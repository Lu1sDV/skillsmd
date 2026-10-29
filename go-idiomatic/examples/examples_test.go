package idiomatic

import (
	"errors"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"slices"
	"testing"
	"unicode/utf8"
)

func ExampleCapture() {
	declared, assigned := Capture()
	fmt.Println(declared)
	fmt.Println(assigned)
	// Output:
	// [1 2 3]
	// [3 3 3]
}

func ExamplePrefix() {
	data := []byte("abcd")
	prefix, err := Prefix(data, 2)
	if err != nil {
		panic(err)
	}
	prefix[0] = 'z'
	fmt.Println(string(data), string(prefix))
	// Output: abcd zb
}

func TestPrefixBoundsAndIsolation(t *testing.T) {
	for _, n := range []int{-1, 4} {
		if _, err := Prefix([]byte("abc"), n); err == nil {
			t.Fatalf("Prefix with length %d accepted", n)
		}
	}
	empty, err := Prefix(nil, 0)
	if err != nil || empty == nil || len(empty) != 0 {
		t.Fatalf("empty prefix = %v, %v; want non-nil empty", empty, err)
	}
	original := []byte("abcd")
	out, err := Prefix(original, 2)
	if err != nil {
		t.Fatal(err)
	}
	original[0] = 'x'
	if string(out) != "ab" {
		t.Fatal("prefix shares source storage")
	}
	view := original[:2:2]
	view[1] = 'y' // Capacity limiting does not isolate existing elements.
	grown := append(view, 'z')
	if string(original) != "xycd" || string(grown) != "xyz" {
		t.Fatalf("limited view: source %q, grown %q", original, grown)
	}
}

func TestRunePrefixBoundaries(t *testing.T) {
	cases := []struct {
		name  string
		text  string
		n     int
		want  string
		fails bool
	}{
		{"empty", "", 0, "", false},
		{"zero", "A世", 0, "", false},
		{"ascii", "A世", 1, "A", false},
		{"multibyte", "A世", 2, "A世", false},
		{"replacement codepoint", "�", 1, "�", false},
		{"too long", "A世", 3, "", true},
		{"negative", "abc", -1, "", true},
		{"invalid utf8", string([]byte{0xff}), 1, "", true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := RunePrefix(tc.text, tc.n)
			if (err != nil) != tc.fails || got != tc.want {
				t.Fatalf("RunePrefix(%q,%d) = %q,%v", tc.text, tc.n, got, err)
			}
		})
	}
	if len("café") != 5 || utf8.RuneCountInString("café") != 4 {
		t.Fatal("incorrect UTF-8 boundary assumption")
	}
}

func TestAddInt64Boundaries(t *testing.T) {
	cases := []struct {
		name       string
		a, b, want int64
		fails      bool
	}{
		{"zero", 0, 0, 0, false},
		{"max", math.MaxInt64 - 1, 1, math.MaxInt64, false},
		{"min", math.MinInt64 + 1, -1, math.MinInt64, false},
		{"positive overflow", math.MaxInt64, 1, 0, true},
		{"negative overflow", math.MinInt64, -1, 0, true},
		{"opposite extremes", math.MinInt64, math.MaxInt64, -1, false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := AddInt64(tc.a, tc.b)
			if errors.Is(err, ErrOverflow) != tc.fails || got != tc.want {
				t.Fatalf("AddInt64(%d,%d) = %d,%v", tc.a, tc.b, got, err)
			}
		})
	}
}

func TestReadFileLimitRealBoundary(t *testing.T) {
	path := filepath.Join(t.TempDir(), "data")
	if err := os.WriteFile(path, []byte("abc"), 0600); err != nil {
		t.Fatal(err)
	}
	got, err := ReadFileLimit(path, 3)
	if err != nil || string(got) != "abc" {
		t.Fatalf("exact limit = %q,%v", got, err)
	}
	if got, err := ReadFileLimit(path, 2); err == nil || got != nil {
		t.Fatalf("oversize must fail, got %q,%v", got, err)
	}
	for _, limit := range []int64{-1, (1 << 20) + 1} {
		if _, err := ReadFileLimit(path, limit); err == nil {
			t.Fatalf("invalid limit %d accepted", limit)
		}
	}
	if _, err := ReadFileLimit(path+".missing", 3); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("missing-file cause lost: %v", err)
	}
	if err := os.WriteFile(path, nil, 0600); err != nil {
		t.Fatal(err)
	}
	if got, err := ReadFileLimit(path, 0); err != nil || len(got) != 0 {
		t.Fatalf("empty file at zero limit = %q,%v", got, err)
	}
	// Reopening the same real file after both success and overflow exercises
	// completed calls, not a fake filesystem. It does not inject Close failures.
	if _, err := ReadFileLimit(path, 0); err != nil {
		t.Fatal(err)
	}
}

func TestCaptureDeclarationVersusAssignment(t *testing.T) {
	declared, assigned := Capture()
	if !slices.Equal(declared, []int{1, 2, 3}) || !slices.Equal(assigned, []int{3, 3, 3}) {
		t.Fatalf("capture = %v,%v", declared, assigned)
	}
}
