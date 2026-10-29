package budget_test

import (
	"errors"
	"fmt"
	"math"
	"math/rand"
	"testing"
	"testing/quick"

	budget "example.com/go-tdd"
)

func newBudget(t *testing.T, capacity int64) *budget.Budget {
	t.Helper()
	b, err := budget.NewBudget(capacity)
	if err != nil {
		t.Fatalf("NewBudget(%d): %v", capacity, err)
	}
	return b
}

func TestBudgetTakeBoundary(t *testing.T) {
	tests := []struct {
		name          string
		amount        int64
		wantRemaining int64
		wantErr       error
	}{
		{"negative", -1, 10, budget.ErrInvalidAmount},
		{"zero", 0, 10, nil},
		{"below", 9, 1, nil},
		{"exact_emptying", 10, 0, nil},
		{"above", 11, 10, budget.ErrInsufficient},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			b := newBudget(t, 10)
			if err := b.Take(tc.amount); !errors.Is(err, tc.wantErr) {
				t.Fatalf("Take(%d) = %v; want %v", tc.amount, err, tc.wantErr)
			}
			if got := b.Remaining(); got != tc.wantRemaining {
				t.Errorf("remaining = %d; want %d", got, tc.wantRemaining)
			}
		})
	}
}

func TestBudgetTransitions(t *testing.T) {
	b := newBudget(t, 10)
	if err := b.Take(4); err != nil {
		t.Fatal(err)
	}
	if got := b.Remaining(); got != 6 {
		t.Fatalf("after taking 4: remaining = %d; want 6", got)
	}
	if err := b.Take(7); !errors.Is(err, budget.ErrInsufficient) {
		t.Fatalf("Take(7) = %v; want insufficient budget", err)
	}
	if got := b.Remaining(); got != 6 {
		t.Fatalf("rejection changed remaining to %d; want 6", got)
	}
	if err := b.Take(6); err != nil {
		t.Fatal(err)
	}
	if err := b.Take(1); !errors.Is(err, budget.ErrInsufficient) {
		t.Fatalf("take after emptying = %v; want insufficient budget", err)
	}
	if got := b.Remaining(); got != 0 {
		t.Errorf("remaining = %d; want 0", got)
	}
}

func TestBudgetZeroValue(t *testing.T) {
	var b budget.Budget
	if err := b.Take(0); err != nil {
		t.Fatalf("zero take on zero value: %v", err)
	}
	if err := b.Take(1); !errors.Is(err, budget.ErrInsufficient) {
		t.Fatalf("Take(1) = %v; want insufficient budget", err)
	}
	if b.Remaining() != 0 {
		t.Fatal("empty budget changed")
	}
}

func TestNewBudgetRejectsNegativeCapacity(t *testing.T) {
	b, err := budget.NewBudget(-1)
	if b != nil || !errors.Is(err, budget.ErrInvalidAmount) {
		t.Fatalf("NewBudget(-1) = %v, %v; want nil, invalid amount", b, err)
	}
}

func TestBudgetIntegerLimits(t *testing.T) {
	b := newBudget(t, math.MaxInt64)
	if err := b.Take(math.MinInt64); !errors.Is(err, budget.ErrInvalidAmount) {
		t.Fatalf("Take(MinInt64) = %v; want invalid amount", err)
	}
	if b.Remaining() != math.MaxInt64 {
		t.Fatal("negative rejection changed budget")
	}
	if err := b.Take(math.MaxInt64); err != nil {
		t.Fatal(err)
	}
	if b.Remaining() != 0 {
		t.Fatal("exact maximum request did not empty budget")
	}
}

// Splitting an affordable request must not change its final observable effect.
func TestBudgetTakeSplit(t *testing.T) {
	property := func(x, y uint16) bool {
		a, b := int64(x), int64(y)
		capacity := a + b
		split, err := budget.NewBudget(capacity)
		if err != nil {
			return false
		}
		whole, err := budget.NewBudget(capacity)
		if err != nil {
			return false
		}
		if split.Take(a) != nil || split.Take(b) != nil || whole.Take(capacity) != nil {
			return false
		}
		return split.Remaining() == 0 && split.Remaining() == whole.Remaining()
	}
	config := &quick.Config{MaxCount: 200, Rand: rand.New(rand.NewSource(1))}
	if err := quick.Check(property, config); err != nil {
		t.Fatal(err)
	}
}

func FuzzBudgetTake(f *testing.F) {
	f.Add(uint16(10), int64(-1))
	f.Add(uint16(10), int64(0))
	f.Add(uint16(10), int64(10))
	f.Add(uint16(10), int64(11))
	f.Add(uint16(0), int64(0))
	f.Fuzz(func(t *testing.T, capacity uint16, amount int64) {
		b := newBudget(t, int64(capacity))
		before := b.Remaining()
		err := b.Take(amount)
		after := b.Remaining()
		if err != nil {
			if amount >= 0 && amount <= before {
				t.Fatalf("affordable request rejected: amount=%d remaining=%d err=%v", amount, before, err)
			}
			if !errors.Is(err, budget.ErrInvalidAmount) && !errors.Is(err, budget.ErrInsufficient) {
				t.Fatalf("unexpected rejection: %v", err)
			}
			if after != before {
				t.Fatalf("rejected request changed remaining: %d -> %d", before, after)
			}
			return
		}
		if amount < 0 || after < 0 || after > before || before-after != amount {
			t.Fatalf("invalid successful transition: before=%d amount=%d after=%d", before, amount, after)
		}
	})
}

func ExampleBudget_Take() {
	b, err := budget.NewBudget(10)
	if err != nil {
		panic(err)
	}
	fmt.Println(errors.Is(b.Take(11), budget.ErrInsufficient), b.Remaining())
	fmt.Println(b.Take(10), b.Remaining())
	// Output:
	// true 10
	// <nil> 0
}

// The timed operation includes construction and one exact-capacity request.
func BenchmarkBudgetNewAndTake(b *testing.B) {
	b.ReportAllocs()
	for b.Loop() {
		capacity, err := budget.NewBudget(10)
		if err != nil {
			b.Fatal(err)
		}
		if err := capacity.Take(10); err != nil {
			b.Fatal(err)
		}
	}
}
