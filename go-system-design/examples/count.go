// Package linecount implements a bounded line-count operation shared by a CLI and HTTP.
package linecount

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"strconv"
	"time"
)

var ErrTooLarge = errors.New("input exceeds byte limit")

// Config is parsed once by the composition root, not inside each request.
type Config struct {
	MaxBytes int64
	Timeout  time.Duration
}

func (c Config) Validate() error {
	if c.MaxBytes < 1 || c.MaxBytes > 64<<20 {
		return errors.New("max bytes must be between 1 and 67108864")
	}
	if c.Timeout <= 0 {
		return errors.New("timeout must be positive")
	}
	return nil
}

// LoadConfig uses defaults unless an environment value is nonempty.
func LoadConfig(getenv func(string) string) (Config, error) {
	cfg := Config{MaxBytes: 1 << 20, Timeout: 3 * time.Second}
	if value := getenv("LINECOUNT_MAX_BYTES"); value != "" {
		limit, err := strconv.ParseInt(value, 10, 64)
		if err != nil {
			return Config{}, fmt.Errorf("LINECOUNT_MAX_BYTES: %w", err)
		}
		cfg.MaxBytes = limit
	}
	if value := getenv("LINECOUNT_TIMEOUT"); value != "" {
		timeout, err := time.ParseDuration(value)
		if err != nil {
			return Config{}, fmt.Errorf("LINECOUNT_TIMEOUT: %w", err)
		}
		cfg.Timeout = timeout
	}
	if err := cfg.Validate(); err != nil {
		return Config{}, fmt.Errorf("linecount config: %w", err)
	}
	return cfg, nil
}

// Count consumes but never closes input. A final non-newline-terminated line counts.
// Cancellation is checked around reading; it cannot unblock an arbitrary Reader.
func Count(ctx context.Context, input io.Reader, maxBytes int64) (int, error) {
	if maxBytes < 1 || maxBytes > 64<<20 {
		return 0, errors.New("max bytes must be between 1 and 67108864")
	}
	if err := ctx.Err(); err != nil {
		return 0, err
	}
	// ponytail: bounded buffering keeps this small example simple; stream when
	// per-request memory at the configured concurrency becomes material.
	data, err := io.ReadAll(io.LimitReader(input, maxBytes+1))
	if err := ctx.Err(); err != nil {
		return 0, err
	}
	if err != nil {
		return 0, fmt.Errorf("read input: %w", err)
	}
	if int64(len(data)) > maxBytes {
		return 0, ErrTooLarge
	}
	lines := bytes.Count(data, []byte{'\n'})
	if len(data) > 0 && data[len(data)-1] != '\n' {
		lines++
	}
	return lines, nil
}
