package algorithms

import (
	"fmt"
	"slices"
	"testing"
)

func ExampleMinWindow() {
	window, err := MinWindow("ADOBECODEBANC", "ABC")
	fmt.Println(window, err)
	window, err = MinWindow("猫a猫犬", "猫犬")
	fmt.Println(window, err)
	// Output:
	// BANC <nil>
	// 猫犬 <nil>
}

func ExampleMedian() {
	var stream Median
	stream.Add(5)
	stream.Add(1)
	stream.Add(9)
	fmt.Println(stream.Middle())
	stream.Add(3)
	fmt.Println(stream.Middle())
	// Output:
	// 5 5 true
	// 3 5 true
}

func TestMinWindowBoundaries(t *testing.T) {
	for _, tc := range []struct {
		name, source, target, want string
	}{
		{"empty target", "abc", "", ""},
		{"both empty", "", "", ""},
		{"empty source", "", "a", ""},
		{"no cover", "ab", "aa", ""},
		{"multiplicity", "abaac", "aac", "aac"},
		{"earliest tie", "abxxba", "ab", "ab"},
		{"rune count not byte count", "猫a猫犬", "猫犬", "猫犬"},
		{"normalization not implicit", "é", "e\u0301", ""},
	} {
		t.Run(tc.name, func(t *testing.T) {
			got, err := MinWindow(tc.source, tc.target)
			if err != nil || got != tc.want {
				t.Fatalf("MinWindow = %q, %v; want %q", got, err, tc.want)
			}
		})
	}
	if _, err := MinWindow(string([]byte{0xff}), ""); err == nil {
		t.Fatal("invalid UTF-8 accepted")
	}
}

// Compare every source of length <=4 and target of length <=2 over a rune
// alphabet with an independent exhaustive-window oracle, including multiplicity.
func TestMinWindowBoundedOracle(t *testing.T) {
	stringsThrough := func(limit int) []string {
		all, level := []string{""}, []string{""}
		for range limit {
			next := make([]string, 0, len(level)*3)
			for _, prefix := range level {
				for _, value := range []rune{'a', 'b', '猫'} {
					next = append(next, prefix+string(value))
				}
			}
			all = append(all, next...)
			level = next
		}
		return all
	}
	for _, source := range stringsThrough(4) {
		for _, target := range stringsThrough(2) {
			got, err := MinWindow(source, target)
			want := bruteWindow(source, target)
			if err != nil || got != want {
				t.Fatalf("MinWindow(%q,%q) = %q,%v; want %q", source, target, got, err, want)
			}
		}
	}
}

func bruteWindow(source, target string) string {
	if target == "" {
		return ""
	}
	text := []rune(source)
	for length := 1; length <= len(text); length++ {
		for start := 0; start+length <= len(text); start++ {
			counts := make(map[rune]int)
			for _, value := range text[start : start+length] {
				counts[value]++
			}
			covered := true
			for _, value := range target {
				counts[value]--
				if counts[value] < 0 {
					covered = false
				}
			}
			if covered {
				return string(text[start : start+length])
			}
		}
	}
	return ""
}

func TestMergeOwnershipAndExtremeComparator(t *testing.T) {
	maxInt := int(^uint(0) >> 1)
	minInt := -maxInt - 1
	input := []Interval{{maxInt, maxInt}, {0, 2}, {minInt, -1}, {2, 3}}
	before := slices.Clone(input)
	got, err := Merge(input)
	want := []Interval{{minInt, -1}, {0, 3}, {maxInt, maxInt}}
	if err != nil || !slices.Equal(got, want) {
		t.Fatalf("Merge = %v,%v; want %v", got, err, want)
	}
	got[0].End = 99
	if !slices.Equal(input, before) {
		t.Fatal("Merge changed or aliased input")
	}
	if result, err := Merge(nil); err != nil || len(result) != 0 {
		t.Fatalf("empty merge = %v,%v", result, err)
	}
	if _, err := Merge([]Interval{{2, 1}}); err == nil {
		t.Fatal("reversed interval accepted")
	}
}

func TestMissingNumberCheckedDomain(t *testing.T) {
	for _, tc := range []struct {
		input []int
		want  int
	}{
		{nil, 0}, {[]int{0}, 1}, {[]int{1}, 0}, {[]int{3, 0, 1}, 2},
	} {
		before := slices.Clone(tc.input)
		got, err := MissingNumber(tc.input)
		if err != nil || got != tc.want || !slices.Equal(tc.input, before) {
			t.Fatalf("MissingNumber(%v) = %d,%v; want %d, unchanged input", before, got, err, tc.want)
		}
	}
	for _, invalid := range [][]int{{1, 1}, {-1}, {2}} {
		if _, err := MissingNumber(invalid); err == nil {
			t.Fatalf("invalid placement input accepted: %v", invalid)
		}
	}
}

func TestHistogramVirtualSentinelAndOverflow(t *testing.T) {
	backing := []int{2, 1, 5, 6, 2, 3, 99}
	got, err := LargestRectangle(backing[:6])
	if err != nil || got != 10 || backing[6] != 99 {
		t.Fatalf("histogram = %d,%v; backing = %v", got, err, backing)
	}
	for _, tc := range []struct {
		heights []int
		want    int
	}{
		{nil, 0}, {[]int{0, 0}, 0}, {[]int{2, 2}, 4}, {[]int{1, 2, 3}, 4},
	} {
		if got, err := LargestRectangle(tc.heights); err != nil || got != tc.want {
			t.Fatalf("histogram(%v) = %d,%v; want %d", tc.heights, got, err, tc.want)
		}
	}
	maxInt := int(^uint(0) >> 1)
	for _, invalid := range [][]int{{-1}, {maxInt, maxInt}} {
		if _, err := LargestRectangle(invalid); err == nil {
			t.Fatalf("invalid/overflowing histogram accepted: %v", invalid)
		}
	}
}

func TestMedianEmptyAndExtremeValues(t *testing.T) {
	var stream Median
	if _, _, ok := stream.Middle(); ok {
		t.Fatal("empty median reported present")
	}
	maxInt := int(^uint(0) >> 1)
	minInt := -maxInt - 1
	values := []int{maxInt, minInt, 0, maxInt, minInt, 0}
	var sorted []int
	for _, value := range values {
		stream.Add(value)
		sorted = append(sorted, value)
		slices.Sort(sorted)
		lower, upper, ok := stream.Middle()
		if !ok || lower != sorted[(len(sorted)-1)/2] || upper != sorted[len(sorted)/2] {
			t.Fatalf("central values = %d,%d,%v; sorted %v", lower, upper, ok, sorted)
		}
	}
}

func TestTopologicalCompleteOrError(t *testing.T) {
	edges := [][2]int{{0, 1}, {0, 1}, {1, 2}}
	order, err := Topological(4, edges) // vertex 3 is isolated
	if err != nil || len(order) != 4 {
		t.Fatalf("topological order = %v,%v", order, err)
	}
	position := make(map[int]int)
	for i, vertex := range order {
		if vertex < 0 || vertex >= 4 {
			t.Fatalf("invalid output vertex: %d", vertex)
		}
		if _, exists := position[vertex]; exists {
			t.Fatalf("repeated vertex: %d", vertex)
		}
		position[vertex] = i
	}
	for _, edge := range edges {
		if position[edge[0]] >= position[edge[1]] {
			t.Fatalf("dependency %v violated by %v", edge, order)
		}
	}
	if got, err := Topological(0, nil); err != nil || len(got) != 0 {
		t.Fatalf("empty DAG = %v,%v", got, err)
	}
	for _, tc := range []struct {
		n     int
		edges [][2]int
	}{
		{2, [][2]int{{0, 1}, {1, 0}}},
		{3, [][2]int{{1, 1}}},
		{2, [][2]int{{0, 2}}},
		{-1, nil},
	} {
		if got, err := Topological(tc.n, tc.edges); err == nil || got != nil {
			t.Fatalf("invalid/cyclic graph returned %v,%v", got, err)
		}
	}
}
