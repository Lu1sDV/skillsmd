package apidesign

import (
	"errors"
	"fmt"
	"iter"
	"sync"
)

// Take is lazy. It never starts source for n <= 0 and never pulls item n+1.
// Downstream early termination is propagated immediately to source.
func Take[T any](source iter.Seq[T], n int) iter.Seq[T] {
	return func(yield func(T) bool) {
		if n <= 0 {
			return
		}
		remaining := n
		for value := range source {
			if !yield(value) {
				return
			}
			remaining--
			if remaining == 0 {
				return
			}
		}
	}
}

// Subject delivers synchronously to an unordered snapshot of its subscribers.
// Callbacks run outside the registry lock and must synchronize their own state
// if Notify calls overlap. Do not copy Subject after its first use.
type Subject[T any] struct {
	mu        sync.Mutex
	nextID    int
	listeners map[int]func(T) error
}

// Subscribe requires a non-nil listener and returns idempotent cancellation.
// Cancellation affects future snapshots, not callbacks already selected.
func (s *Subject[T]) Subscribe(listener func(T) error) func() {
	s.mu.Lock()
	if s.listeners == nil {
		s.listeners = make(map[int]func(T) error)
	}
	id := s.nextID
	s.nextID++
	s.listeners[id] = listener
	s.mu.Unlock()
	return func() {
		s.mu.Lock()
		delete(s.listeners, id)
		s.mu.Unlock()
	}
}

func (s *Subject[T]) Notify(event T) error {
	s.mu.Lock()
	callbacks := make([]func(T) error, 0, len(s.listeners))
	for _, listener := range s.listeners {
		callbacks = append(callbacks, listener)
	}
	s.mu.Unlock()
	var failures []error
	for _, callback := range callbacks {
		if err := callback(event); err != nil {
			failures = append(failures, err)
		}
	}
	return errors.Join(failures...)
}

type Status uint8

const (
	Pending Status = iota
	Paid
	Shipped
	Delivered
	Cancelled
)

type Action string

// Transition computes a local state change; it performs no external effect.
func Transition(current Status, action Action) (Status, error) {
	switch {
	case current == Pending && action == "pay":
		return Paid, nil
	case current == Paid && action == "ship":
		return Shipped, nil
	case current == Shipped && action == "deliver":
		return Delivered, nil
	case (current == Pending || current == Paid) && action == "cancel":
		return Cancelled, nil
	default:
		return current, fmt.Errorf("action %q not allowed in state %d", action, current)
	}
}
