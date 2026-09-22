// runtool.go — `vrdb run-tool` launch wrapper (T3-07 / forensic NEW-1, C28; the mechanism for
// the standing tool-launch memory-cap doctrine T1-22).
//
// Every heavy-native tool launch (CPG builder, symbolizer, fuzzer, sanitizer build) must run
// under a memory cap + concurrency=1 + a flock, so a campaign stops re-learning the OOM cap per
// target. This wrapper is AGNOSTIC: it caps any command, in the skill, not per-target.
//
//   - Memory cap: `systemd-run --scope -p MemoryMax=<cap> -p MemorySwapMax=0 …` when systemd-run
//     is available; otherwise a soft `ulimit -v` (RLIMIT_AS) fallback via /bin/sh. Capability is
//     DETECTED, never faked — Capabilities() reports what is actually enforceable here.
//   - Concurrency=1 + flock: an exclusive advisory lock on a per-tool lockfile serializes
//     launches of the SAME tool so two heavy lanes never contend for RAM simultaneously.

package vrdb

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
)

// RunToolOpts configures a capped tool launch.
type RunToolOpts struct {
	// MemoryMax is the cgroup MemoryMax value (e.g. "20G", "512M"). Required.
	MemoryMax string
	// LockName names the per-tool flock; launches sharing a LockName are serialized
	// (concurrency=1). Defaults to the program basename when empty.
	LockName string
	// LockDir is where the lockfile lives; defaults to os.TempDir().
	LockDir string
	// Stdout/Stderr/Stdin are wired to the child if set (else inherited from os.*).
	Stdout, Stderr *os.File
	Stdin          *os.File
}

// RunToolCapabilities reports which capping mechanisms are available in THIS environment, so a
// caller (and a test) can branch honestly instead of assuming systemd is present.
type RunToolCapabilities struct {
	SystemdRun bool // `systemd-run` on PATH (cgroup MemoryMax cap available)
	Flock      bool // `flock` advisory locking available (always true on Linux via syscall)
	UlimitAS   bool // /bin/sh + ulimit -v fallback available
}

// RunToolCaps detects the available capping mechanisms.
func RunToolCaps() RunToolCapabilities {
	caps := RunToolCapabilities{Flock: true} // flock(2) is used directly, always available on linux
	if _, err := exec.LookPath("systemd-run"); err == nil {
		caps.SystemdRun = true
	}
	if _, err := exec.LookPath("sh"); err == nil {
		caps.UlimitAS = true
	}
	return caps
}

// RunTool runs argv[0] argv[1:] under a memory cap + an exclusive per-tool flock (T3-07).
// It returns the child's exit error (nil on success). The cap mechanism is chosen by capability:
// systemd-run (preferred) → ulimit -v (fallback). If NEITHER is available, RunTool returns an
// error rather than silently running uncapped — the cap is the point of the wrapper.
func RunTool(ctx context.Context, argv []string, opts RunToolOpts) error {
	if len(argv) == 0 {
		return fmt.Errorf("vrdb: run-tool: empty command")
	}
	if opts.MemoryMax == "" {
		return fmt.Errorf("vrdb: run-tool: MemoryMax is required (the cap is the point of the wrapper)")
	}

	// --- concurrency=1: exclusive advisory flock on a per-tool lockfile ---
	lockName := opts.LockName
	if lockName == "" {
		lockName = filepath.Base(argv[0])
	}
	lockDir := opts.LockDir
	if lockDir == "" {
		lockDir = os.TempDir()
	}
	if err := os.MkdirAll(lockDir, 0o755); err != nil {
		return fmt.Errorf("vrdb: run-tool: lock dir: %w", err)
	}
	lockPath := filepath.Join(lockDir, "vrdb-runtool-"+sanitizeLabel(lockName)+".lock")
	lf, err := os.OpenFile(lockPath, os.O_CREATE|os.O_RDWR, 0o644)
	if err != nil {
		return fmt.Errorf("vrdb: run-tool: open lockfile: %w", err)
	}
	defer lf.Close()
	if err := syscall.Flock(int(lf.Fd()), syscall.LOCK_EX); err != nil {
		return fmt.Errorf("vrdb: run-tool: acquire flock: %w", err)
	}
	defer syscall.Flock(int(lf.Fd()), syscall.LOCK_UN)

	// --- memory cap: build the wrapped command ---
	caps := RunToolCaps()
	var cmd *exec.Cmd
	switch {
	case caps.SystemdRun:
		// `systemd-run --user --scope --quiet -p MemoryMax=<cap> -p MemorySwapMax=0 -- argv…`
		wrapped := []string{
			"--user", "--scope", "--quiet",
			"-p", "MemoryMax=" + opts.MemoryMax,
			"-p", "MemorySwapMax=0",
			"--",
		}
		wrapped = append(wrapped, argv...)
		cmd = exec.CommandContext(ctx, "systemd-run", wrapped...)
	case caps.UlimitAS:
		// Soft fallback: RLIMIT_AS via `ulimit -v <kb>` then exec the command. MemoryMax is
		// parsed to KiB; on a parse failure we error rather than run uncapped.
		kb, perr := memoryMaxToKiB(opts.MemoryMax)
		if perr != nil {
			return fmt.Errorf("vrdb: run-tool: parse MemoryMax %q: %w", opts.MemoryMax, perr)
		}
		shline := fmt.Sprintf("ulimit -v %d; exec \"$@\"", kb)
		shArgs := append([]string{"-c", shline, "vrdb-run-tool"}, argv...)
		cmd = exec.CommandContext(ctx, "sh", shArgs...)
	default:
		return fmt.Errorf("vrdb: run-tool: no memory-cap mechanism available (neither systemd-run nor sh+ulimit); refusing to run uncapped")
	}

	if opts.Stdout != nil {
		cmd.Stdout = opts.Stdout
	} else {
		cmd.Stdout = os.Stdout
	}
	if opts.Stderr != nil {
		cmd.Stderr = opts.Stderr
	} else {
		cmd.Stderr = os.Stderr
	}
	if opts.Stdin != nil {
		cmd.Stdin = opts.Stdin
	} else {
		cmd.Stdin = os.Stdin
	}

	return cmd.Run()
}

// memoryMaxToKiB parses a MemoryMax string (e.g. "20G", "512M", "1048576K", "2000000000") into
// KiB for `ulimit -v`. Suffixes K/M/G (binary) are honored; a bare number is bytes.
func memoryMaxToKiB(s string) (int64, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return 0, fmt.Errorf("empty")
	}
	mult := int64(1)
	last := s[len(s)-1]
	num := s
	switch last {
	case 'K', 'k':
		mult = 1
		num = s[:len(s)-1]
	case 'M', 'm':
		mult = 1024
		num = s[:len(s)-1]
	case 'G', 'g':
		mult = 1024 * 1024
		num = s[:len(s)-1]
	default:
		// bare bytes → KiB
		mult = 0 // signal "bytes"
	}
	var val int64
	for _, c := range num {
		if c < '0' || c > '9' {
			return 0, fmt.Errorf("non-numeric component %q", num)
		}
		val = val*10 + int64(c-'0')
	}
	if val <= 0 {
		return 0, fmt.Errorf("non-positive")
	}
	if mult == 0 {
		// bytes → KiB
		return val / 1024, nil
	}
	return val * mult, nil
}
