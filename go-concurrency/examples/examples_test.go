package concurrency_test

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"sync/atomic"
	"testing"
	"testing/synctest"

	concurrency "example.com/go-concurrency"
)

func ExampleForEach() {
	var results []int
	err := concurrency.ForEach(context.Background(), 2, []int{1, 2, 3},
		func(_ context.Context, n int) (int, error) { return n * n, nil },
		func(n int) error {
			results = append(results, n)
			return nil
		})
	slices.Sort(results)
	fmt.Println(results, err)
	// Output: [1 4 9] <nil>
}

func TestForEachBoundedWorkersAndJoin(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		const workers = 2
		release := make(chan struct{})
		var active atomic.Int64
		var consumed int
		done := make(chan error, 1)
		go func() {
			done <- concurrency.ForEach(context.Background(), workers, []int{1, 2, 3, 4, 5},
				func(_ context.Context, n int) (int, error) {
					active.Add(1)
					defer active.Add(-1)
					<-release
					return n, nil
				},
				func(int) error { consumed++; return nil })
		}()
		synctest.Wait()
		if got := active.Load(); got != workers {
			t.Errorf("blocked active calls = %d; want %d", got, workers)
		}
		close(release)
		if err := <-done; err != nil {
			t.Fatal(err)
		}
		if active.Load() != 0 || consumed != 5 {
			t.Fatalf("after join: active=%d consumed=%d", active.Load(), consumed)
		}
	})
}

func TestForEachFirstWorkerErrorSurvivesSiblingCancellation(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		failure := errors.New("source failed")
		secondStarted := make(chan struct{})
		secondStopped := make(chan struct{})
		err := concurrency.ForEach(context.Background(), 2, []int{1, 2, 3},
			func(ctx context.Context, n int) (int, error) {
				if n == 1 {
					<-secondStarted
					return 0, failure
				}
				if n == 2 {
					close(secondStarted)
					defer close(secondStopped)
					<-ctx.Done()
					return 0, ctx.Err()
				}
				t.Error("admitted trailing work after source failure")
				return n, nil
			},
			func(int) error { return nil })
		if !errors.Is(err, failure) {
			t.Fatalf("error = %v; want source failure", err)
		}
		select {
		case <-secondStopped:
		default:
			t.Fatal("returned before sibling cleanup")
		}
	})
}

func TestForEachEarlyConsumerExitJoinsBlockedSenders(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		stop := errors.New("consumer has enough")
		items := make([]int, 100)
		consumerStarted := make(chan struct{})
		stopConsumer := make(chan struct{})
		done := make(chan error, 1)
		var consumed int
		var active atomic.Int64
		go func() {
			done <- concurrency.ForEach(context.Background(), 2, items,
				func(_ context.Context, n int) (int, error) {
					active.Add(1)
					defer active.Add(-1)
					return n, nil
				},
				func(int) error {
					consumed++
					close(consumerStarted)
					<-stopConsumer
					return stop
				})
		}()
		<-consumerStarted
		synctest.Wait() // Consumer held; workers now blocked sending results.
		close(stopConsumer)
		err := <-done
		if !errors.Is(err, stop) || consumed != 1 || active.Load() != 0 {
			t.Fatalf("error=%v consumed=%d active=%d", err, consumed, active.Load())
		}
	})
}

func TestForEachCancellationIsNotPreemption(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()
		started := make(chan struct{})
		release := make(chan struct{})
		done := make(chan error, 1)
		go func() {
			done <- concurrency.ForEach(ctx, 1, []int{1, 2},
				func(context.Context, int) (int, error) {
					close(started)
					<-release // Deliberately ignores cancellation until released.
					return 1, nil
				},
				func(int) error { t.Error("consumed after cancellation"); return nil })
		}()
		<-started
		cancel()
		synctest.Wait()
		select {
		case err := <-done:
			close(release)
			t.Fatalf("returned before arbitrary work finished: %v", err)
		default:
		}
		close(release)
		if err := <-done; !errors.Is(err, context.Canceled) {
			t.Fatalf("error = %v; want canceled", err)
		}
	})
}

func TestForEachEmptyInvalidAndPreCanceled(t *testing.T) {
	identity := func(_ context.Context, n int) (int, error) { return n, nil }
	discard := func(int) error { return nil }
	if err := concurrency.ForEach(context.Background(), 1, nil, identity, discard); err != nil {
		t.Fatal(err)
	}
	for _, workers := range []int{-1, 0} {
		if err := concurrency.ForEach(context.Background(), workers, nil, identity, discard); err == nil {
			t.Fatalf("accepted workers=%d", workers)
		}
	}
	if err := concurrency.ForEach(context.Background(), 1, nil, nil, discard); err == nil {
		t.Fatal("accepted nil work")
	}
	if err := concurrency.ForEach(context.Background(), 1, nil, identity, nil); err == nil {
		t.Fatal("accepted nil consume")
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	err := concurrency.ForEach(ctx, 1, []int{1},
		func(context.Context, int) (int, error) { t.Error("started canceled work"); return 0, nil }, discard)
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("error = %v; want canceled", err)
	}
}

func TestClosedBufferedAndNilChannels(t *testing.T) {
	ch := make(chan int, 1)
	ch <- 7
	close(ch)
	if value, ok := <-ch; value != 7 || !ok {
		t.Fatalf("buffered receive = %d, %v", value, ok)
	}
	if value, ok := <-ch; value != 0 || ok {
		t.Fatalf("drained receive = %d, %v", value, ok)
	}
	var disabled <-chan int
	select {
	case <-disabled:
		t.Fatal("nil channel selected")
	default:
	}
}
