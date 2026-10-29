package boundaries

import (
	"encoding/csv"
	"errors"
	"fmt"
	"io"
	"slices"
	"strings"
	"testing"
)

func ExampleReadSettings() {
	settings, err := ReadSettings(strings.NewReader(`{"name":"Ada","limit":3}`))
	if err != nil {
		panic(err)
	}
	fmt.Printf("%s: %d\n", settings.Name, settings.Limit)
	// Output: Ada: 3
}

func TestReadSettingsRejectsInvalidDocuments(t *testing.T) {
	for name, input := range map[string]string{
		"empty":          "",
		"null":           "null",
		"unknown field":  `{"name":"Ada","limit":1,"extra":true}`,
		"trailing value": `{"name":"Ada","limit":1} null`,
		"trailing junk":  `{"name":"Ada","limit":1}!`,
		"truncated":      `{"name":"Ada","limit":1`,
		"wrong type":     `{"name":"Ada","limit":"1"}`,
		"empty name":     `{"name":" ","limit":1}`,
		"zero limit":     `{"name":"Ada","limit":0}`,
		"excess limit":   `{"name":"Ada","limit":101}`,
	} {
		t.Run(name, func(t *testing.T) {
			got, err := ReadSettings(strings.NewReader(input))
			if !errors.Is(err, ErrInvalidSettings) || got != (Settings{}) {
				t.Fatalf("got %#v, %v; want zero settings and ErrInvalidSettings", got, err)
			}
		})
	}
}

func TestReadSettingsSizeBoundary(t *testing.T) {
	document := `{"name":"Ada","limit":100}`
	exact := document + strings.Repeat(" ", MaxSettingsBytes-len(document))
	got, err := ReadSettings(strings.NewReader(exact))
	if err != nil || got != (Settings{Name: "Ada", Limit: 100}) {
		t.Fatalf("exact limit: got %#v, %v", got, err)
	}
	got, err = ReadSettings(strings.NewReader(exact + " "))
	if !errors.Is(err, ErrTooLarge) || got != (Settings{}) {
		t.Fatalf("over limit: got %#v, %v; want ErrTooLarge", got, err)
	}
}

// A valid Reader may return final bytes and an error in the same call.
type endingReader struct {
	data []byte
	err  error
}

func (r *endingReader) Read(p []byte) (int, error) {
	n := copy(p, r.data)
	r.data = r.data[n:]
	if len(r.data) == 0 {
		return n, r.err
	}
	return n, nil
}

func TestReadSettingsPreservesReadContract(t *testing.T) {
	document := []byte(`{"name":"Ada","limit":1}`)
	got, err := ReadSettings(&endingReader{data: document, err: io.EOF})
	if err != nil || got != (Settings{Name: "Ada", Limit: 1}) {
		t.Fatalf("bytes with EOF: got %#v, %v", got, err)
	}
	failed := errors.New("transport interrupted")
	got, err = ReadSettings(&endingReader{data: document, err: failed})
	if !errors.Is(err, failed) || got != (Settings{}) {
		t.Fatalf("bytes with error: got %#v, %v; want transport failure", got, err)
	}
}

type failedWriter struct{ err error }

func (w failedWriter) Write([]byte) (int, error) { return 0, w.err }

func Example_csvFlushError() {
	failed := errors.New("destination full")
	writer := csv.NewWriter(failedWriter{err: failed})
	if err := writer.Write([]string{"Ada", "3"}); err != nil {
		panic(err)
	}
	writer.Flush()
	fmt.Println(errors.Is(writer.Error(), failed))
	// Output: true
}

func Example_linesAndReverse() {
	for line := range strings.Lines("a\nb\nc") {
		fmt.Printf("%q\n", line)
	}
	for _, value := range slices.Backward([]int{10, 20}) {
		fmt.Println(value)
	}
	// Output:
	// "a\n"
	// "b\n"
	// "c"
	// 20
	// 10
}
