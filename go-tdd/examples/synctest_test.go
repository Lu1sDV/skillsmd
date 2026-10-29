package budget_test

import (
	"context"
	"errors"
	"testing"
	"testing/synctest"
	"time"
)

// This is a stdlib API recipe, not application coverage for Budget.
func TestDeadlineBoundary(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		const timeout = 5 * time.Second
		ctx, cancel := context.WithTimeout(t.Context(), timeout)
		defer cancel()

		time.Sleep(timeout - time.Nanosecond)
		synctest.Wait()
		if err := ctx.Err(); err != nil {
			t.Fatalf("before deadline: %v; want nil", err)
		}

		time.Sleep(time.Nanosecond)
		synctest.Wait()
		if err := ctx.Err(); !errors.Is(err, context.DeadlineExceeded) {
			t.Fatalf("at deadline: %v; want deadline exceeded", err)
		}
	})
}
