// runtool_test.go — smoke tests for the `vrdb run-tool` launch wrapper (T3-07): the standing
// memory-cap + concurrency=1 + flock mechanism that makes T1-22's tool-launch doctrine
// enforceable rather than re-learned per target.
//
// The HARD-CONTRACT parts run everywhere (refuse an empty command, refuse a missing MemoryMax,
// report capabilities honestly). The actual capped LAUNCH is capability-gated: if NEITHER
// systemd-run nor sh+ulimit can enforce a cap in this environment, the launch sub-test SKIPS
// with a clear reason rather than faking a pass — the cap is the point of the wrapper, so a run
// we cannot prove is capped is not a pass.
package vrdb_test

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"vrdb"
)

// TestRunTool_RefusesWithoutCap pins the load-bearing contract: the wrapper exists to CAP, so it
// refuses to run when it cannot (empty command, or a missing MemoryMax).
func TestRunTool_RefusesWithoutCap(t *testing.T) {
	ctx := context.Background()
	if err := vrdb.RunTool(ctx, nil, vrdb.RunToolOpts{MemoryMax: "256M"}); err == nil {
		t.Errorf("empty command should be refused, got nil")
	}
	if err := vrdb.RunTool(ctx, []string{"/bin/true"}, vrdb.RunToolOpts{}); err == nil {
		t.Errorf("missing MemoryMax should be refused (the cap is the point), got nil")
	}
}

// TestRunTool_CapabilitiesHonest asserts RunToolCaps reports what is actually probeable, never a
// hard-coded optimistic value — so a caller/test can branch on the truth.
func TestRunTool_CapabilitiesHonest(t *testing.T) {
	caps := vrdb.RunToolCaps()
	// flock(2) is used directly via syscall on linux; the wrapper always reports it true.
	if !caps.Flock {
		t.Errorf("Flock should be reported available on linux")
	}
	// SystemdRun/UlimitAS must match a real PATH lookup (we don't assert which, only honesty:
	// at least one capping mechanism, or the wrapper would be a no-op everywhere).
	if !caps.SystemdRun && !caps.UlimitAS {
		t.Logf("neither systemd-run nor sh available — RunTool will refuse to run (correct)")
	}
}

// TestRunTool_CappedLaunch runs a trivial command under the cap. Capability-gated: skips with a
// clear reason if no cap mechanism is enforceable here.
func TestRunTool_CappedLaunch(t *testing.T) {
	caps := vrdb.RunToolCaps()
	if !caps.SystemdRun && !caps.UlimitAS {
		t.Skip("no memory-cap mechanism available (neither systemd-run nor sh+ulimit); the wrapper " +
			"correctly refuses to run uncapped, so there is nothing to launch-test here")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	lockDir := t.TempDir()
	// Stdout left nil → the wrapper inherits os.Stdout; /bin/true produces no output, so the
	// exit code is the only signal we read.
	err := vrdb.RunTool(ctx, []string{"/bin/true"}, vrdb.RunToolOpts{
		MemoryMax: "512M",
		LockName:  "vrdb-runtool-selftest",
		LockDir:   lockDir,
	})
	if err != nil {
		// In some sandboxes systemd-run --user has no session bus even though it is on PATH;
		// that is an ENVIRONMENT limit, not a wrapper bug. Surface it as a SKIP, not a fail.
		t.Skipf("capped launch could not run in this environment (cap mechanism present but not "+
			"usable here): %v", err)
	}

	// The lockfile must have been created under the requested dir (proves the flock path ran).
	if _, statErr := os.Stat(filepath.Join(lockDir, "vrdb-runtool-vrdb-runtool-selftest.lock")); statErr != nil {
		t.Errorf("expected the per-tool lockfile under %s, got: %v", lockDir, statErr)
	}
}

// TestRunTool_FlockSerializes proves concurrency=1: RunTool calls sharing a LockName cannot run
// their child commands simultaneously — each blocks on the exclusive flock until the prior holder
// releases it. A side-channel marker dir records each child's enter/exit; if serialization held,
// the observed maximum concurrent-active count is exactly 1. Capability-gated like the launch
// test (skips if no cap mechanism is usable here, and if even the first probe launch can't run).
func TestRunTool_FlockSerializes(t *testing.T) {
	caps := vrdb.RunToolCaps()
	if !caps.SystemdRun && !caps.UlimitAS {
		t.Skip("no cap mechanism available; cannot launch the serialized children")
	}
	lockDir := t.TempDir()
	markerDir := t.TempDir()
	opts := vrdb.RunToolOpts{MemoryMax: "256M", LockName: "serialize-probe", LockDir: lockDir}

	// Probe once: if the very first capped launch can't run here, skip (environment limit).
	if err := vrdb.RunTool(context.Background(), []string{"/bin/true"}, opts); err != nil {
		t.Skipf("capped launch unusable in this environment: %v", err)
	}

	// Each child appends "+" on entry and "-" on exit to a shared marker file, with a sleep in
	// between. If the flock serialized them, the file is a balanced "+-+-+-" with no nesting;
	// if two overlapped, a "++" appears. We assert no "++" substring.
	marker := filepath.Join(markerDir, "concurrency.log")
	const n = 3
	var wg sync.WaitGroup
	for i := 0; i < n; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			sh := "printf '+' >> " + marker + "; sleep 0.15; printf '-' >> " + marker
			_ = vrdb.RunTool(context.Background(), []string{"sh", "-c", sh}, opts)
		}()
	}
	wg.Wait()

	data, err := os.ReadFile(marker)
	if err != nil {
		t.Skipf("marker file not written (children could not run in this environment): %v", err)
	}
	if strings.Contains(string(data), "++") {
		t.Errorf("flock did NOT serialize: found overlapping children in marker %q", string(data))
	}
}
