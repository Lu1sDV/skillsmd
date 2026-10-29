package apidesign

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"maps"
	"slices"
	"strings"
)

// Integer deliberately accepts two underlying integer families, not all numbers.
type Integer interface{ ~int | ~int64 }

func Sum[T Integer](values []T) T {
	var total T
	for _, value := range values {
		total += value
	}
	return total
}

// GroupBy preserves input order within each group, not map iteration order.
// Elements are copied shallowly. key must not return an unhashable dynamic value.
func GroupBy[T any, K comparable](values []T, key func(T) K) map[K][]T {
	groups := make(map[K][]T)
	for _, value := range values {
		k := key(value)
		groups[k] = append(groups[k], value)
	}
	return groups
}

func Equal[T comparable](a, b T) bool { return a == b }

type Stack[T any] struct{ items []T }

func (s *Stack[T]) Push(value T) { s.items = append(s.items, value) }

func (s *Stack[T]) Pop() (T, bool) {
	if len(s.items) == 0 {
		var zero T
		return zero, false
	}
	last := len(s.items) - 1
	value := s.items[last]
	var zero T
	s.items[last] = zero
	s.items = s.items[:last]
	return value, true
}

// Document is mutable. Clone creates independent tags and metadata byte slices.
type Document struct {
	Title    string
	Tags     []string
	Metadata map[string][]byte
}

func (d Document) Clone() Document {
	d.Tags = slices.Clone(d.Tags)
	d.Metadata = maps.Clone(d.Metadata)
	for key, value := range d.Metadata {
		d.Metadata[key] = slices.Clone(value)
	}
	return d
}

// DocumentBuilder's zero value is usable; Build requires a nonblank title.
// Build snapshots its data. Reusing the builder never changes an earlier result.
type DocumentBuilder struct {
	title string
	tags  []string
}

func (b *DocumentBuilder) Title(title string) *DocumentBuilder {
	b.title = title
	return b
}

func (b *DocumentBuilder) Tag(tag string) *DocumentBuilder {
	b.tags = append(b.tags, tag)
	return b
}

func (b *DocumentBuilder) Build() (Document, error) {
	if strings.TrimSpace(b.title) == "" {
		return Document{}, errors.New("title is required")
	}
	return Document{Title: b.title, Tags: slices.Clone(b.tags)}, nil
}

type JSONFamily struct {
	Encode func(any) ([]byte, error)
	Decode func([]byte, any) error
}

func NewJSONFamily() JSONFamily {
	return JSONFamily{Encode: json.Marshal, Decode: json.Unmarshal}
}

func WriteMessage(w io.Writer, message string) error {
	_, err := io.WriteString(w, message)
	return err
}

type exportConfig struct {
	prefix string
	limit  int
}

// Option runs during construction. Nil options and invalid settings are rejected.
// Scalar settings use last-valid-option-wins; any invalid option ends construction.
type Option func(*exportConfig) error

func WithPrefix(prefix string) Option {
	return func(config *exportConfig) error {
		if strings.ContainsAny(prefix, "\r\n") {
			return errors.New("prefix must not contain a newline")
		}
		config.prefix = prefix
		return nil
	}
}

func WithLimit(limit int) Option {
	return func(config *exportConfig) error {
		if limit <= 0 {
			return errors.New("byte limit must be positive")
		}
		config.limit = limit
		return nil
	}
}

// Exporter borrows a writer and is not concurrency-safe. Its zero value is unusable.
// The writer must be a non-nil implementation, not an interface holding a typed nil.
// Exporter never closes the caller-owned writer.
type Exporter struct {
	writer io.Writer
	config exportConfig
}

func NewExporter(writer io.Writer, options ...Option) (*Exporter, error) {
	if writer == nil {
		return nil, errors.New("writer is required")
	}
	config := exportConfig{limit: 4096}
	for _, option := range options {
		if option == nil {
			return nil, errors.New("nil option")
		}
		if err := option(&config); err != nil {
			return nil, fmt.Errorf("configure exporter: %w", err)
		}
	}
	return &Exporter{writer: writer, config: config}, nil
}

// Write validates the full UTF-8 byte count before writing anything.
// A writer failure may have written a prefix; no rollback is promised.
func (e *Exporter) Write(message string) error {
	if len(e.config.prefix) > e.config.limit || len(message) > e.config.limit-len(e.config.prefix) {
		return errors.New("message exceeds byte limit")
	}
	text := e.config.prefix + message
	n, err := io.WriteString(e.writer, text)
	if err != nil {
		return fmt.Errorf("write message: %w", err)
	}
	if n != len(text) {
		return io.ErrShortWrite
	}
	return nil
}
