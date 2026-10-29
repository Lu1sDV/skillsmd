package boundaries

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strings"
)

const MaxSettingsBytes = 256

var (
	ErrTooLarge        = errors.New("settings exceed size limit")
	ErrInvalidSettings = errors.New("invalid settings")
)

type Settings struct {
	Name  string `json:"name"`
	Limit int    `json:"limit"`
}

// ReadSettings accepts exactly one bounded JSON object. It borrows r and retains
// encoding/json v1's duplicate-key, case-folding and Unicode replacement rules.
func ReadSettings(r io.Reader) (Settings, error) {
	data, err := io.ReadAll(io.LimitReader(r, MaxSettingsBytes+1))
	if err != nil {
		return Settings{}, fmt.Errorf("read settings: %w", err)
	}
	if len(data) > MaxSettingsBytes {
		return Settings{}, ErrTooLarge
	}
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	var settings *Settings
	if err := decoder.Decode(&settings); err != nil {
		return Settings{}, fmt.Errorf("%w: %w", ErrInvalidSettings, err)
	}
	var extra any
	if err := decoder.Decode(&extra); err != io.EOF {
		if err == nil {
			return Settings{}, fmt.Errorf("%w: multiple JSON values", ErrInvalidSettings)
		}
		return Settings{}, fmt.Errorf("%w: trailing data: %w", ErrInvalidSettings, err)
	}
	if settings == nil || strings.TrimSpace(settings.Name) == "" || settings.Limit < 1 || settings.Limit > 100 {
		return Settings{}, fmt.Errorf("%w: name required and limit must be 1..100", ErrInvalidSettings)
	}
	return *settings, nil
}
