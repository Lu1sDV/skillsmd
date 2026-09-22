// go.mod — module manifest for the vuln-research DuckDB put/fetch harness.
// Exists so the v2 orchestrator can flush row events and read findings without re-implementing single-writer + hash-idempotency invariants per session.
// Built with `go build ./...` from this dir; tests run via `go test ./...`; the canonical schema is mirrored from ../schema.sql via go:generate (see schema.go).

module vrdb

go 1.25

require (
	github.com/marcboeker/go-duckdb v1.8.5
	gopkg.in/yaml.v3 v3.0.1
)

require (
	github.com/apache/arrow-go/v18 v18.1.0 // indirect
	github.com/go-viper/mapstructure/v2 v2.2.1 // indirect
	github.com/goccy/go-json v0.10.5 // indirect
	github.com/google/flatbuffers v25.1.24+incompatible // indirect
	github.com/google/uuid v1.6.0 // indirect
	github.com/klauspost/compress v1.17.11 // indirect
	github.com/klauspost/cpuid/v2 v2.2.9 // indirect
	github.com/pierrec/lz4/v4 v4.1.22 // indirect
	github.com/zeebo/xxh3 v1.0.2 // indirect
	golang.org/x/exp v0.0.0-20250128182459-e0ece0dbea4c // indirect
	golang.org/x/mod v0.22.0 // indirect
	golang.org/x/sync v0.10.0 // indirect
	golang.org/x/sys v0.29.0 // indirect
	golang.org/x/tools v0.29.0 // indirect
	golang.org/x/xerrors v0.0.0-20240903120638-7835f813f4da // indirect
)
