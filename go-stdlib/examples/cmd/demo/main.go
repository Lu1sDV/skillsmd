package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"

	boundaries "example.com/go-stdlib"
)

func run(in io.Reader, out io.Writer) error {
	settings, err := boundaries.ReadSettings(in)
	if err != nil {
		return err
	}
	return json.NewEncoder(out).Encode(settings)
}

func main() {
	if err := run(os.Stdin, os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
