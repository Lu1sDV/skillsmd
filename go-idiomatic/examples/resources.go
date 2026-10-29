package idiomatic

import (
	"errors"
	"fmt"
	"io"
	"os"
)

// ReadFileLimit reads at most limit bytes, rejecting rather than truncating excess.
func ReadFileLimit(path string, limit int64) (data []byte, err error) {
	if limit < 0 || limit > 1<<20 {
		return nil, fmt.Errorf("limit %d outside [0,1048576]", limit)
	}
	f, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("open %q: %w", path, err)
	}
	defer func() {
		if closeErr := f.Close(); closeErr != nil {
			err = errors.Join(err, fmt.Errorf("close %q: %w", path, closeErr))
		}
	}()
	data, err = io.ReadAll(io.LimitReader(f, limit+1))
	if err != nil {
		return nil, fmt.Errorf("read %q: %w", path, err)
	}
	if int64(len(data)) > limit {
		return nil, fmt.Errorf("read %q: exceeds limit %d", path, limit)
	}
	return data, nil
}
