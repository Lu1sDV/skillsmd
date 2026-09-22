// hash.go — the pinned content-fingerprint recipe (T3-04 / S-D07).
//
// The over-dedup failure (3 distinct boundary_fuzz crashes collapsed into 1 gr_findings row,
// gotchas #5) happens because the dedup natural key / *_hash is caller-chosen and can be too
// weak a discriminator. The fix is two-part: (1) every hash-keyed table carries a
// content_fingerprint column (sha256 of the full semantic row, schema T2-13); (2) on an
// ON CONFLICT against the NK, the harness COMPARES the incoming fingerprint to the stored one
// and REJECTS the batch when they differ ("hash collision: weak discriminator", put.go).
//
// ContentFingerprint pins the recipe so the agent cannot pick a weak one: it length-prefixes
// each (column,value) pair so no value can straddle a delimiter into another field — the exact
// collision db-logging §4 warns about with the `|`-join ("a symbol_path containing `|` cannot
// straddle into body"). Sorting columns makes the fingerprint order-independent.

package vrdb

import (
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"fmt"
	"sort"
)

// fingerprintExcludedColumns are columns that must NOT enter the content fingerprint: the
// surrogate id (assigned by the harness, not semantic), the dedup natural-key hash itself, the
// fingerprint column, and volatile bookkeeping timestamps. Excluding them keeps the fingerprint
// a stable function of the row's SEMANTIC content, so an idempotent replay fingerprints
// identically while a genuinely different body fingerprints differently.
var fingerprintExcludedColumns = map[string]struct{}{
	"id":                  {},
	"content_fingerprint": {},
	"created_at":          {},
	"updated_at":          {},
	"mutated_at":          {},
	"decided_at":          {},
	"started_at":          {},
	"ended_at":            {},
	"scanned_at":          {},
	"observed_at":         {},
}

// ContentFingerprint computes the pinned sha256 fingerprint of a row's semantic columns.
// The encoding is length-prefixed and column-sorted so it is unambiguous and order-independent:
//
//	for each (col, val) in sorted(row), excluding non-semantic columns:
//	    write uint32(len(col)) ‖ col ‖ uint32(len(valStr)) ‖ valStr
//
// where valStr is the canonical string rendering of the value (fmt %v; nil → the empty string
// with a distinguishing 0xFFFFFFFF length sentinel so an absent column differs from "").
// Returns the lowercase hex digest.
func ContentFingerprint(row map[string]any) string {
	cols := make([]string, 0, len(row))
	for k := range row {
		if _, skip := fingerprintExcludedColumns[k]; skip {
			continue
		}
		cols = append(cols, k)
	}
	sort.Strings(cols)

	h := sha256.New()
	var lenbuf [4]byte
	for _, c := range cols {
		binary.BigEndian.PutUint32(lenbuf[:], uint32(len(c)))
		h.Write(lenbuf[:])
		h.Write([]byte(c))

		v := row[c]
		if v == nil {
			// NULL sentinel: a length no real string can have, so NULL ≠ "".
			binary.BigEndian.PutUint32(lenbuf[:], ^uint32(0))
			h.Write(lenbuf[:])
			continue
		}
		s := fmt.Sprintf("%v", v)
		binary.BigEndian.PutUint32(lenbuf[:], uint32(len(s)))
		h.Write(lenbuf[:])
		h.Write([]byte(s))
	}
	return hex.EncodeToString(h.Sum(nil))
}
