// Package budget demonstrates a small, observable state-transition contract.
package budget

import "errors"

var (
	ErrInvalidAmount = errors.New("amount must be nonnegative")
	ErrInsufficient  = errors.New("insufficient budget")
)

// Budget tracks nonnegative units. It is not safe for concurrent use.
// The zero value is an empty budget; copying a Budget creates independent state.
type Budget struct {
	remaining int64
}

// NewBudget rejects negative capacity.
func NewBudget(capacity int64) (*Budget, error) {
	if capacity < 0 {
		return nil, ErrInvalidAmount
	}
	return &Budget{remaining: capacity}, nil
}

// Remaining reports the available units.
func (b *Budget) Remaining() int64 {
	return b.remaining
}

// Take consumes amount units. Zero is allowed, including on an empty budget.
// A rejected request leaves the available units unchanged.
func (b *Budget) Take(amount int64) error {
	if amount < 0 {
		return ErrInvalidAmount
	}
	if amount > b.remaining {
		return ErrInsufficient
	}
	b.remaining -= amount
	return nil
}
