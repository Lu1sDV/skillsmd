package main

import (
	"errors"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"slices"

	idiomatic "example.com/go-idiomatic"
)

func run() (err error) {
	declared, assigned := idiomatic.Capture()
	if !slices.Equal(declared, []int{1, 2, 3}) || !slices.Equal(assigned, []int{3, 3, 3}) {
		return errors.New("loop capture boundary failed")
	}
	original := []byte("abcd")
	prefix, err := idiomatic.Prefix(original, 2)
	if err != nil {
		return err
	}
	prefix[0] = 'z'
	if string(original) != "abcd" {
		return errors.New("prefix aliases source")
	}
	text, err := idiomatic.RunePrefix("A世界", 2)
	if err != nil || text != "A世" {
		return fmt.Errorf("UTF-8 prefix = %q, %v", text, err)
	}
	if _, err := idiomatic.AddInt64(math.MaxInt64, 1); !errors.Is(err, idiomatic.ErrOverflow) {
		return fmt.Errorf("overflow boundary: %v", err)
	}
	dir, err := os.MkdirTemp("", "go-idiomatic-")
	if err != nil {
		return err
	}
	defer func() { err = errors.Join(err, os.RemoveAll(dir)) }()
	path := filepath.Join(dir, "data")
	if err := os.WriteFile(path, []byte("abc"), 0600); err != nil {
		return err
	}
	data, err := idiomatic.ReadFileLimit(path, 3)
	if err != nil || string(data) != "abc" {
		return fmt.Errorf("exact file boundary = %q, %v", data, err)
	}
	if _, err := idiomatic.ReadFileLimit(path, 2); err == nil {
		return errors.New("oversize file accepted")
	}
	_, err = fmt.Printf(
		"loops: declared %v assigned %v\nstorage: %s %s\n"+
			"UTF-8: %s\noverflow rejected; file limit enforced\n",
		declared, assigned, original, prefix, text,
	)
	return err
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
