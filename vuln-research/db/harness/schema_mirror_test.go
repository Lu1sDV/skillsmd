// schema_mirror_test.go — drift guard ensuring the embedded schema.sql mirror
// stays in sync with the canonical db/schema.sql. If this test fails, run:
//
//	go generate ./...
//
// (or: cd db/harness && sh -c "{ sed -n '1,4p' schema.sql; cat ../schema.sql; } > schema.sql.gen && mv schema.sql.gen schema.sql")

package vrdb_test

import (
	"os"
	"strings"
	"testing"
)

// TestSchemaMirrorInSync asserts that db/harness/schema.sql (the embedded mirror)
// ends with the canonical db/schema.sql verbatim, after trimming trailing whitespace.
// The mirror has a 4-line header followed by the canonical content; this test checks
// the suffix relationship so the header is ignored but any drift in the body fails fast.
func TestSchemaMirrorInSync(t *testing.T) {
	t.Helper()

	canonicalBytes, err := os.ReadFile("../schema.sql")
	if err != nil {
		t.Fatalf("read canonical ../schema.sql: %v", err)
	}
	mirrorBytes, err := os.ReadFile("schema.sql")
	if err != nil {
		t.Fatalf("read mirror schema.sql: %v", err)
	}

	canonical := strings.TrimRight(string(canonicalBytes), " \t\n\r")
	mirror := strings.TrimRight(string(mirrorBytes), " \t\n\r")

	if !strings.HasSuffix(mirror, canonical) {
		t.Errorf("db/harness/schema.sql is out of sync with db/schema.sql.\n"+
			"Run `go generate ./...` (or the documented regen command) to resync:\n"+
			"  cd db/harness && sh -c \"{ sed -n '1,4p' schema.sql; cat ../schema.sql; } > schema.sql.gen && mv schema.sql.gen schema.sql\"\n\n"+
			"Mirror length: %d bytes, canonical length: %d bytes",
			len(mirror), len(canonical))
	}
}
