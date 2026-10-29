package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"

	linecount "example.com/go-system-design"
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(args []string) (err error) {
	if len(args) == 0 || (args[0] != "count" && args[0] != "demo") {
		return errors.New("usage: demo count [file|-] | demo demo")
	}
	if (args[0] == "demo" && len(args) != 1) || len(args) > 2 {
		return errors.New("usage: demo count [file|-] | demo demo")
	}
	cfg, err := linecount.LoadConfig(os.Getenv)
	if err != nil {
		return err
	}
	ctx := context.Background()
	if args[0] == "demo" {
		return linecount.Demo(ctx, cfg, os.Stdout)
	}
	var input io.Reader = os.Stdin
	if len(args) == 2 && args[1] != "-" {
		file, openErr := os.Open(args[1])
		if openErr != nil {
			return fmt.Errorf("open input: %w", openErr)
		}
		defer func() {
			err = errors.Join(err, file.Close())
		}()
		input = file
	}
	lines, err := linecount.Count(ctx, input, cfg.MaxBytes)
	if err != nil {
		return err
	}
	_, err = fmt.Fprintln(os.Stdout, lines)
	return err
}
