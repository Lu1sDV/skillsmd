package apidesign

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"iter"
	"os"
	"reflect"
	"slices"
	"sync"
	"testing"
)

func ExampleSum() {
	type UserID int
	fmt.Println(Sum([]UserID{2, 3}))
	fmt.Println(GroupBy([]string{"a", "bb", "c"}, func(s string) int { return len(s) })[1])
	// Output:
	// 5
	// [a c]
}

func ExampleExporter() {
	var output bytes.Buffer
	exporter, err := NewExporter(&output, WithPrefix("note: "), WithLimit(20))
	if err != nil {
		panic(err)
	}
	if err := exporter.Write("hello"); err != nil {
		panic(err)
	}
	fmt.Println(output.String())
	// Output: note: hello
}

func TestStackEmptyAndRemovedSlot(t *testing.T) {
	var stack Stack[*int]
	if value, ok := stack.Pop(); value != nil || ok {
		t.Fatalf("empty Pop = %v, %v", value, ok)
	}
	number := 7
	stack.Push(&number)
	storage := stack.items
	if value, ok := stack.Pop(); value != &number || !ok {
		t.Fatalf("Pop = %v, %v", value, ok)
	}
	if storage[0] != nil {
		t.Fatal("removed value retained in backing array")
	}
}

func TestComparableDynamicSlicePanics(t *testing.T) {
	defer func() {
		if recover() == nil {
			t.Fatal("interface equality with equal dynamic slice types must panic")
		}
	}()
	Equal[any]([]int{1}, []int{1})
}

func TestTypedNilAndMethodSet(t *testing.T) {
	var file *os.File
	var writer io.Writer = file
	if writer == nil {
		t.Fatal("typed nil writer unexpectedly became a nil interface")
	}
	if _, ok := any(bytes.Buffer{}).(io.Writer); ok {
		t.Fatal("bytes.Buffer value must not implement pointer-receiver Write")
	}
	if _, ok := any(new(bytes.Buffer)).(io.Writer); !ok {
		t.Fatal("*bytes.Buffer must implement io.Writer")
	}
}

func TestBuilderReuseAndCloneOwnership(t *testing.T) {
	var builder DocumentBuilder
	if _, err := builder.Build(); err == nil {
		t.Fatal("empty title accepted")
	}
	first, err := builder.Title("Guide").Tag("go").Build()
	if err != nil {
		t.Fatal(err)
	}
	second, err := builder.Title("Updated").Tag("api").Build()
	if err != nil {
		t.Fatal(err)
	}
	second.Tags[0] = "changed"
	if first.Title != "Guide" || !slices.Equal(first.Tags, []string{"go"}) {
		t.Fatalf("builder reuse changed previous result: %+v", first)
	}
	first.Metadata = map[string][]byte{"owner": []byte("alice")}
	cloned := first.Clone()
	cloned.Tags[0] = "different"
	cloned.Metadata["owner"][0] = 'X'
	cloned.Metadata["new"] = []byte("new")
	if first.Tags[0] != "go" || string(first.Metadata["owner"]) != "alice" || len(first.Metadata) != 1 {
		t.Fatalf("clone aliases original: %+v", first)
	}
}

func TestJSONFamilyRoundTrip(t *testing.T) {
	codec := NewJSONFamily()
	original := Document{Title: "Guide", Tags: []string{"go"}, Metadata: map[string][]byte{"id": []byte("a")}}
	encoded, err := codec.Encode(original)
	if err != nil {
		t.Fatal(err)
	}
	var decoded Document
	if err := codec.Decode(encoded, &decoded); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(decoded, original) {
		t.Fatalf("round trip = %+v, want %+v", decoded, original)
	}
	if err := codec.Decode([]byte("{"), &decoded); err == nil {
		t.Fatal("invalid JSON accepted")
	}
}

func TestOptionsRejectBeforeWriting(t *testing.T) {
	for _, option := range []Option{nil, WithPrefix("bad\n"), WithLimit(0), WithLimit(-1)} {
		var output bytes.Buffer
		if exporter, err := NewExporter(&output, option); err == nil || exporter != nil {
			t.Fatalf("invalid option returned %v, %v", exporter, err)
		}
		if output.Len() != 0 {
			t.Fatal("construction wrote output")
		}
	}
	if _, err := NewExporter(nil); err == nil {
		t.Fatal("nil writer accepted")
	}
	var output bytes.Buffer
	exporter, err := NewExporter(&output, WithPrefix("old"), WithPrefix("é"), WithLimit(3))
	if err != nil {
		t.Fatal(err)
	}
	if err := exporter.Write("ab"); err == nil || output.Len() != 0 {
		t.Fatalf("byte limit failure = %v, output = %q", err, output.String())
	}
	if err := exporter.Write("a"); err != nil || output.String() != "éa" {
		t.Fatalf("exact byte limit = %v, output = %q", err, output.String())
	}
}

type shortWriter struct{}

func (shortWriter) Write(p []byte) (int, error) { return len(p) - 1, nil }

type failingWriter struct{ err error }

func (w failingWriter) Write([]byte) (int, error) { return 0, w.err }

func TestExporterPreservesWriterFailures(t *testing.T) {
	failure := errors.New("disk full")
	for _, tc := range []struct {
		name   string
		writer io.Writer
		want   error
	}{
		{"short write", shortWriter{}, io.ErrShortWrite},
		{"write error", failingWriter{failure}, failure},
	} {
		t.Run(tc.name, func(t *testing.T) {
			exporter, err := NewExporter(tc.writer)
			if err != nil {
				t.Fatal(err)
			}
			if err := exporter.Write("hello"); !errors.Is(err, tc.want) {
				t.Fatalf("Write error = %v, want %v", err, tc.want)
			}
		})
	}
}

func TestOnceValuesCachesInitializationError(t *testing.T) {
	calls := 0
	failure := errors.New("unavailable")
	load := sync.OnceValues(func() (string, error) {
		calls++
		return "", failure
	})
	for range 2 {
		if value, err := load(); value != "" || !errors.Is(err, failure) {
			t.Fatalf("load = %q, %v", value, err)
		}
	}
	if calls != 1 {
		t.Fatalf("initializer called %d times", calls)
	}
}

// eofReader deliberately returns useful bytes and EOF together on its one read.
type eofReader struct{}

func (eofReader) Read(p []byte) (int, error) { return copy(p, "ok"), io.EOF }

func TestReaderDecoratorPreservesBytesBeforeEOF(t *testing.T) {
	var observed bytes.Buffer
	reader := io.TeeReader(eofReader{}, &observed)
	buffer := make([]byte, 8)
	n, err := reader.Read(buffer)
	if n != 2 || !errors.Is(err, io.EOF) || string(buffer[:n]) != "ok" || observed.String() != "ok" {
		t.Fatalf("Read = %d, %v, bytes %q, observed %q", n, err, buffer[:n], observed.String())
	}
}

func TestTakeDoesNotOverpull(t *testing.T) {
	for _, tc := range []struct {
		name  string
		limit int
		stop  bool
		want  []int
		pulls int
	}{
		{"negative", -1, false, nil, 0},
		{"zero", 0, false, nil, 0},
		{"one", 1, false, []int{0}, 1},
		{"early break", 4, true, []int{0}, 1},
	} {
		t.Run(tc.name, func(t *testing.T) {
			pulls := 0
			source := iter.Seq[int](func(yield func(int) bool) {
				for value := range 5 {
					pulls++
					if !yield(value) {
						return
					}
				}
			})
			var got []int
			for value := range Take(source, tc.limit) {
				got = append(got, value)
				if tc.stop {
					break
				}
			}
			if !slices.Equal(got, tc.want) || pulls != tc.pulls {
				t.Fatalf("values = %v, pulls = %d; want %v, %d", got, pulls, tc.want, tc.pulls)
			}
		})
	}
}

func TestTakeCanReplay(t *testing.T) {
	limited := Take(slices.Values([]int{1, 2, 3}), 2)
	for range 2 {
		if got := slices.Collect(limited); !slices.Equal(got, []int{1, 2}) {
			t.Fatalf("replayed values = %v, want [1 2]", got)
		}
	}
}

func TestObserverCanUnsubscribeItself(t *testing.T) {
	var subject Subject[int]
	calls := 0
	var unsubscribe func()
	unsubscribe = subject.Subscribe(func(value int) error {
		calls += value
		unsubscribe()
		return nil
	})
	if err := subject.Notify(2); err != nil {
		t.Fatal(err)
	}
	unsubscribe()
	if err := subject.Notify(3); err != nil {
		t.Fatal(err)
	}
	if calls != 2 {
		t.Fatalf("callback total = %d, want 2", calls)
	}
}

func TestObserverAttemptsEveryCallbackAndJoinsErrors(t *testing.T) {
	var subject Subject[int]
	first := errors.New("first")
	second := errors.New("second")
	calls := 0
	subject.Subscribe(func(int) error { calls++; return first })
	subject.Subscribe(func(int) error { calls++; return second })
	err := subject.Notify(1)
	if calls != 2 || !errors.Is(err, first) || !errors.Is(err, second) {
		t.Fatalf("calls = %d, error = %v", calls, err)
	}
}

func TestTransitionRejectsWithoutChangingState(t *testing.T) {
	if next, err := Transition(Pending, "ship"); err == nil || next != Pending {
		t.Fatalf("illegal transition = %v, %v", next, err)
	}
	state := Pending
	for _, action := range []Action{"pay", "ship", "deliver"} {
		next, err := Transition(state, action)
		if err != nil {
			t.Fatal(err)
		}
		state = next
	}
	if state != Delivered {
		t.Fatalf("final state = %v", state)
	}
	if next, err := Transition(state, "cancel"); err == nil || next != Delivered {
		t.Fatalf("terminal transition = %v, %v", next, err)
	}
}
