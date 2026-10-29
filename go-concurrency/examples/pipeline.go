// Package concurrency demonstrates owned, bounded concurrent processing.
package concurrency

import (
	"context"
	"errors"
	"sync"
)

// ForEach maps items with at most workers concurrent work calls, then calls
// consume serially in completion order, not input order. There is no queued
// channel backlog. The caller owns items and must not mutate it during the call.
//
// The first callback error registered wins; cancellation stops admission and
// signals callbacks. ForEach joins every goroutine before returning. Callbacks
// must not panic, and work must return on its own or cooperate with cancellation:
// cancellation cannot preempt arbitrary work. consume must also return promptly.
// To stop consuming early, return a caller-owned sentinel error from consume.
func ForEach(
	parent context.Context,
	workers int,
	items []int,
	work func(context.Context, int) (int, error),
	consume func(int) error,
) error {
	if workers <= 0 {
		return errors.New("workers must be positive")
	}
	if work == nil || consume == nil {
		return errors.New("work and consume must be non-nil")
	}
	if err := parent.Err(); err != nil {
		return err
	}

	ctx, cancel := context.WithCancel(parent)
	defer cancel()
	jobs := make(chan int)
	results := make(chan int)
	var firstError error
	var first sync.Once
	fail := func(err error) {
		first.Do(func() {
			firstError = err
			cancel()
		})
	}

	var consumers sync.WaitGroup
	consumers.Go(func() {
		for value := range results {
			if ctx.Err() != nil {
				continue
			}
			if err := consume(value); err != nil {
				fail(err)
			}
		}
	})

	var producers sync.WaitGroup
	for range workers {
		producers.Go(func() {
			for {
				if ctx.Err() != nil {
					return
				}
				select {
				case <-ctx.Done():
					return
				case value, ok := <-jobs:
					if !ok {
						return
					}
					if ctx.Err() != nil {
						return
					}
					result, err := work(ctx, value)
					if err != nil {
						fail(err)
						return
					}
					select {
					case results <- result:
					case <-ctx.Done():
						return
					}
				}
			}
		})
	}

admission:
	for _, value := range items {
		if ctx.Err() != nil {
			break
		}
		select {
		case jobs <- value:
		case <-ctx.Done():
			break admission
		}
	}
	close(jobs)
	producers.Wait()
	close(results)
	consumers.Wait()
	if firstError != nil {
		return firstError
	}
	return ctx.Err()
}
