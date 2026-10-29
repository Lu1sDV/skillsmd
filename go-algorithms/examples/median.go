package algorithms

import "container/heap"

type intHeap struct {
	values  []int
	maximum bool
}

func (h intHeap) Len() int { return len(h.values) }
func (h intHeap) Less(i, j int) bool {
	if h.maximum {
		return h.values[i] > h.values[j]
	}
	return h.values[i] < h.values[j]
}
func (h intHeap) Swap(i, j int)   { h.values[i], h.values[j] = h.values[j], h.values[i] }
func (h *intHeap) Push(value any) { h.values = append(h.values, value.(int)) }
func (h *intHeap) Pop() any {
	last := len(h.values) - 1
	value := h.values[last]
	h.values[last] = 0
	h.values = h.values[:last]
	return value
}

// Median maintains central integer values of a growing stream. The zero value
// is ready to use. Do not copy a Median after use; it is not concurrency-safe.
type Median struct {
	lower intHeap
	upper intHeap
}

// Add preserves the ordered-half and size invariants in O(log(n+1)) time.
func (m *Median) Add(value int) {
	m.lower.maximum = true
	heap.Push(&m.lower, value)
	heap.Push(&m.upper, heap.Pop(&m.lower))
	if m.upper.Len() > m.lower.Len() {
		heap.Push(&m.lower, heap.Pop(&m.upper))
	}
}

// Middle returns the two central values (equal for an odd-sized stream).
// The exact median is their mathematical mean, without overflowing integer sum
// or silently converting 64-bit integers to an inexact float64 here.
func (m *Median) Middle() (lower, upper int, ok bool) {
	if m.lower.Len() == 0 {
		return 0, 0, false
	}
	lower = m.lower.values[0]
	upper = lower
	if m.lower.Len() == m.upper.Len() {
		upper = m.upper.values[0]
	}
	return lower, upper, true
}
