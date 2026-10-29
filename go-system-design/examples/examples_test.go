package linecount_test

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	linecount "example.com/go-system-design"
)

func ExampleCount() {
	lines, err := linecount.Count(context.Background(), strings.NewReader("one\ntwo"), 7)
	fmt.Println(lines, err)
	// Output: 2 <nil>
}

func TestCountLineAndByteBoundaries(t *testing.T) {
	for _, test := range []struct {
		name  string
		input string
		limit int64
		want  int
		err   error
	}{
		{name: "empty", input: "", limit: 1, want: 0},
		{name: "blank line", input: "\n", limit: 1, want: 1},
		{name: "exact limit", input: "one\ntwo\n", limit: 8, want: 2},
		{name: "unterminated final line", input: "one\ntwo", limit: 7, want: 2},
		{name: "over limit", input: "one\ntwo\n!", limit: 8, err: linecount.ErrTooLarge},
	} {
		t.Run(test.name, func(t *testing.T) {
			got, err := linecount.Count(context.Background(), strings.NewReader(test.input), test.limit)
			if got != test.want || !errors.Is(err, test.err) {
				t.Fatalf("Count = (%d, %v), want (%d, %v)", got, err, test.want, test.err)
			}
		})
	}
}

type failingReader struct{ err error }

func (r failingReader) Read([]byte) (int, error) { return 0, r.err }

type cancelingReader struct{ cancel context.CancelFunc }

func (r cancelingReader) Read(p []byte) (int, error) {
	r.cancel()
	return copy(p, "x"), io.EOF
}

func TestCountPreservesReadAndContextErrors(t *testing.T) {
	readErr := errors.New("storage unavailable")
	if _, err := linecount.Count(context.Background(), failingReader{readErr}, 8); !errors.Is(err, readErr) {
		t.Fatalf("read error lost: %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := linecount.Count(ctx, failingReader{readErr}, 8); !errors.Is(err, context.Canceled) {
		t.Fatalf("pre-canceled context = %v", err)
	}
	ctx, cancel = context.WithCancel(context.Background())
	defer cancel()
	if _, err := linecount.Count(ctx, cancelingReader{cancel}, 8); !errors.Is(err, context.Canceled) {
		t.Fatalf("cancellation during read = %v", err)
	}
}

func TestConfigDefaultsOverridesAndRejectedValues(t *testing.T) {
	cfg, err := linecount.LoadConfig(func(string) string { return "" })
	if err != nil || cfg.MaxBytes != 1<<20 || cfg.Timeout != 3*time.Second {
		t.Fatalf("defaults = %+v, %v", cfg, err)
	}
	cfg, err = linecount.LoadConfig(func(key string) string {
		return map[string]string{"LINECOUNT_MAX_BYTES": "8", "LINECOUNT_TIMEOUT": "2s"}[key]
	})
	if err != nil || cfg.MaxBytes != 8 || cfg.Timeout != 2*time.Second {
		t.Fatalf("overrides = %+v, %v", cfg, err)
	}
	for _, test := range []struct{ key, value string }{
		{"LINECOUNT_MAX_BYTES", "0"},
		{"LINECOUNT_MAX_BYTES", "67108865"},
		{"LINECOUNT_MAX_BYTES", "many"},
		{"LINECOUNT_TIMEOUT", "0s"},
		{"LINECOUNT_TIMEOUT", "soon"},
	} {
		t.Run(test.key+"="+test.value, func(t *testing.T) {
			_, err := linecount.LoadConfig(func(key string) string {
				if key == test.key {
					return test.value
				}
				return ""
			})
			if err == nil {
				t.Fatal("invalid configuration accepted")
			}
		})
	}
}

func TestHTTPAdapterMapsBehaviorAndErrors(t *testing.T) {
	handler, err := linecount.NewHandler(linecount.Config{MaxBytes: 8, Timeout: time.Second})
	if err != nil {
		t.Fatal(err)
	}
	for _, test := range []struct {
		name   string
		method string
		body   string
		status int
		want   string
	}{
		{"count", http.MethodPost, "one\ntwo\n", http.StatusOK, "{\"lines\":2}\n"},
		{"over limit", http.MethodPost, "one\ntwo\n!", http.StatusRequestEntityTooLarge, "input too large\n"},
		{"wrong method", http.MethodGet, "", http.StatusMethodNotAllowed, "Method Not Allowed\n"},
	} {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest(test.method, "/count", strings.NewReader(test.body))
			recorder := httptest.NewRecorder()
			handler.ServeHTTP(recorder, request)
			if recorder.Code != test.status || recorder.Body.String() != test.want {
				t.Fatalf("response = %d %q, want %d %q", recorder.Code, recorder.Body.String(), test.status, test.want)
			}
		})
	}
	t.Run("request cancellation", func(t *testing.T) {
		ctx, cancel := context.WithCancel(context.Background())
		cancel()
		request := httptest.NewRequest(http.MethodPost, "/count", strings.NewReader("one")).WithContext(ctx)
		recorder := httptest.NewRecorder()
		handler.ServeHTTP(recorder, request)
		if recorder.Code != http.StatusRequestTimeout {
			t.Fatalf("canceled request status = %d", recorder.Code)
		}
	})
}
