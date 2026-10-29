package idiomatic

import (
	"errors"
	"fmt"
	"math"
	"unicode/utf8"
)

var ErrOverflow = errors.New("integer overflow")

// AddInt64 rejects overflow before performing the addition.
func AddInt64(a, b int64) (int64, error) {
	if (b > 0 && a > math.MaxInt64-b) || (b < 0 && a < math.MinInt64-b) {
		return 0, ErrOverflow
	}
	return a + b, nil
}

// Prefix returns independent storage; n counts bytes, not Unicode characters.
func Prefix(data []byte, n int) ([]byte, error) {
	if n < 0 || n > len(data) {
		return nil, fmt.Errorf("prefix length %d outside [0,%d]", n, len(data))
	}
	out := make([]byte, n)
	copy(out, data[:n])
	return out, nil
}

// RunePrefix returns the first n code points, not grapheme clusters.
// The returned string may retain the original string's storage.
func RunePrefix(text string, n int) (string, error) {
	if n < 0 || !utf8.ValidString(text) {
		return "", errors.New("expected valid UTF-8 and nonnegative rune count")
	}
	count := 0
	for i := range text {
		if count == n {
			return text[:i], nil
		}
		count++
	}
	if count == n {
		return text, nil
	}
	return "", fmt.Errorf("rune count %d exceeds %d", n, count)
}

// Capture contrasts declaration and assignment under Go 1.22+ language semantics.
func Capture() (declared, assigned []int) {
	var fresh []func() int
	for _, n := range []int{1, 2, 3} {
		fresh = append(fresh, func() int { return n })
	}
	for _, f := range fresh {
		declared = append(declared, f())
	}
	var reused []func() int
	var n int
	for _, n = range []int{1, 2, 3} {
		reused = append(reused, func() int { return n })
	}
	for _, f := range reused {
		assigned = append(assigned, f())
	}
	return declared, assigned
}
