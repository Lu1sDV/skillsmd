package main

import (
	"fmt"
	"os"

	algorithms "example.com/go-algorithms"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run() error {
	window, err := algorithms.MinWindow("ADOBECODEBANC", "ABC")
	if err != nil {
		return err
	}
	merged, err := algorithms.Merge([]algorithms.Interval{
		{Start: 5, End: 8}, {Start: 1, End: 3}, {Start: 3, End: 6},
	})
	if err != nil {
		return err
	}
	missing, err := algorithms.MissingNumber([]int{3, 0, 1})
	if err != nil {
		return err
	}
	area, err := algorithms.LargestRectangle([]int{2, 1, 5, 6, 2, 3})
	if err != nil {
		return err
	}
	var stream algorithms.Median
	for _, value := range []int{5, 1, 9, 3} {
		stream.Add(value)
	}
	lower, upper, ok := stream.Middle()
	order, err := algorithms.Topological(4, [][2]int{{0, 1}, {0, 2}, {2, 3}})
	if err != nil {
		return err
	}
	_, err = fmt.Printf(
		"window: %s\nmerged: %v\nmissing: %d\nhistogram: %d\n"+
			"median central values: %d %d %t\ndependency order: %v\n",
		window, merged, missing, area, lower, upper, ok, order,
	)
	return err
}
