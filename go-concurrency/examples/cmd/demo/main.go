package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"slices"
	"time"

	concurrency "example.com/go-concurrency"
)

func run() error {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	var squares []int
	err := concurrency.ForEach(ctx, 2, []int{1, 2, 3, 4},
		func(ctx context.Context, n int) (int, error) {
			if err := ctx.Err(); err != nil {
				return 0, err
			}
			return n * n, nil
		},
		func(n int) error { squares = append(squares, n); return nil })
	if err != nil {
		return err
	}
	slices.Sort(squares)

	stop := errors.New("consumer has enough")
	consumed := 0
	err = concurrency.ForEach(ctx, 2, []int{1, 2, 3, 4},
		func(_ context.Context, n int) (int, error) { return n, nil },
		func(int) error { consumed++; return stop })
	if !errors.Is(err, stop) || consumed != 1 {
		return fmt.Errorf("early stop: consumed=%d error=%v", consumed, err)
	}
	_, err = fmt.Printf("squares: %v\nearly stop: joined after one result\n", squares)
	return err
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
