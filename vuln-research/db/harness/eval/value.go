// value.go — loose coercions for DuckDB-scanned values (int32/int64/float64/string/nil)
// returned by vrdb.Fetch. Exists so ingest/score can read columns without repeating a
// type switch at every call site; mirrors how the harness reads numerics elsewhere.

package eval

import (
	"strconv"
	"strings"
)

// asString renders a Fetch value as a string; nil becomes "".
func asString(v any) string {
	if v == nil {
		return ""
	}
	if s, ok := v.(string); ok {
		return s
	}
	return strconv.FormatInt(asInt64(v), 10)
}

// asInt coerces a Fetch value to int (DuckDB INTEGER scans as int32/int64).
func asInt(v any) int { return int(asInt64(v)) }

func asInt64(v any) int64 {
	switch n := v.(type) {
	case int64:
		return n
	case int32:
		return int64(n)
	case int:
		return int64(n)
	case float64:
		return int64(n)
	default:
		return 0
	}
}

// asFloat coerces a Fetch value to float64 (DuckDB REAL scans as float64; NULL -> 0).
func asFloat(v any) float64 {
	switch n := v.(type) {
	case float64:
		return n
	case float32:
		return float64(n)
	case int64:
		return float64(n)
	case int32:
		return float64(n)
	default:
		return 0
	}
}

func lower(s string) string { return strings.ToLower(strings.TrimSpace(s)) }
