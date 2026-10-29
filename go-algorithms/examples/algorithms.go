// Package algorithms demonstrates checked, nonmutating algorithm boundaries.
package algorithms

import (
	"cmp"
	"fmt"
	"slices"
	"unicode/utf8"
)

// MinWindow returns the earliest shortest rune window covering target's rune
// multiplicities. Empty target or no cover returns "". Invalid UTF-8 is an error.
func MinWindow(source, target string) (string, error) {
	if !utf8.ValidString(source) || !utf8.ValidString(target) {
		return "", fmt.Errorf("source and target must be valid UTF-8")
	}
	if target == "" {
		return "", nil
	}
	text, wanted := []rune(source), []rune(target)
	if len(wanted) > len(text) {
		return "", nil
	}
	need := make(map[rune]int)
	for _, value := range wanted {
		need[value]++
	}
	missing, left := len(wanted), 0
	bestStart, bestLen := 0, len(text)+1
	for right, value := range text {
		if need[value] > 0 {
			missing--
		}
		need[value]--
		for missing == 0 {
			if size := right - left + 1; size < bestLen {
				bestStart, bestLen = left, size
			}
			outgoing := text[left]
			need[outgoing]++
			if need[outgoing] > 0 {
				missing++
			}
			left++
		}
	}
	if bestLen > len(text) {
		return "", nil
	}
	return string(text[bestStart : bestStart+bestLen]), nil
}

// Interval is a closed interval with Start <= End.
type Interval struct {
	Start, End int
}

// Merge coalesces closed intervals without sorting or changing input.
// The returned value elements are independent of input.
func Merge(input []Interval) ([]Interval, error) {
	for _, interval := range input {
		if interval.Start > interval.End {
			return nil, fmt.Errorf("reversed interval: %v", interval)
		}
	}
	ordered := slices.Clone(input)
	slices.SortFunc(ordered, func(a, b Interval) int {
		if c := cmp.Compare(a.Start, b.Start); c != 0 {
			return c
		}
		return cmp.Compare(a.End, b.End)
	})
	count := 0
	for _, current := range ordered {
		if count == 0 || current.Start > ordered[count-1].End {
			ordered[count] = current
			count++
		} else {
			ordered[count-1].End = max(ordered[count-1].End, current.End)
		}
	}
	return ordered[:count], nil
}

// MissingNumber accepts n distinct values in [0,n], preserving input.
// Validation and copying intentionally make auxiliary space O(n), not O(1).
func MissingNumber(input []int) (int, error) {
	n := len(input)
	seen := make([]bool, n+1)
	for _, value := range input {
		if value < 0 || value > n {
			return 0, fmt.Errorf("value %d outside [0,%d]", value, n)
		}
		if seen[value] {
			return 0, fmt.Errorf("duplicate value %d", value)
		}
		seen[value] = true
	}
	nums := slices.Clone(input)
	for i := 0; i < n; {
		value := nums[i]
		if value < n && value != i {
			nums[i], nums[value] = nums[value], nums[i]
		} else {
			i++
		}
	}
	for i, value := range nums {
		if i != value {
			return i, nil
		}
	}
	return n, nil
}

// LargestRectangle returns histogram area without writing input or spare capacity.
// Negative heights and areas that cannot fit in int are errors.
func LargestRectangle(heights []int) (int, error) {
	for _, height := range heights {
		if height < 0 {
			return 0, fmt.Errorf("negative height %d", height)
		}
	}
	stack := make([]int, 0, len(heights))
	best := 0
	maxInt := int(^uint(0) >> 1)
	for i := 0; i <= len(heights); i++ {
		current := 0 // virtual sentinel; do not append to caller's backing array
		if i < len(heights) {
			current = heights[i]
		}
		for len(stack) > 0 && heights[stack[len(stack)-1]] > current {
			last := stack[len(stack)-1]
			stack = stack[:len(stack)-1]
			width := i
			if len(stack) > 0 {
				width = i - stack[len(stack)-1] - 1
			}
			if heights[last] > maxInt/width {
				return 0, fmt.Errorf("rectangle area overflows int")
			}
			best = max(best, heights[last]*width)
		}
		if i < len(heights) {
			stack = append(stack, i)
		}
	}
	return best, nil
}

// Topological returns a full order for vertices [0,n) and directed [from,to]
// edges. Duplicate edges are counted consistently. A cycle returns no order.
func Topological(n int, edges [][2]int) ([]int, error) {
	if n < 0 {
		return nil, fmt.Errorf("negative vertex count %d", n)
	}
	for _, edge := range edges {
		if edge[0] < 0 || edge[0] >= n || edge[1] < 0 || edge[1] >= n {
			return nil, fmt.Errorf("edge %v outside vertex range [0,%d)", edge, n)
		}
	}
	graph := make([][]int, n)
	indegree := make([]int, n)
	for _, edge := range edges {
		graph[edge[0]] = append(graph[edge[0]], edge[1])
		indegree[edge[1]]++
	}
	order := make([]int, 0, n)
	for vertex, degree := range indegree {
		if degree == 0 {
			order = append(order, vertex)
		}
	}
	for head := 0; head < len(order); head++ {
		for _, next := range graph[order[head]] {
			indegree[next]--
			if indegree[next] == 0 {
				order = append(order, next)
			}
		}
	}
	if len(order) != n {
		return nil, fmt.Errorf("directed cycle prevents a complete order")
	}
	return order, nil
}
