#!/usr/bin/env python3
"""Emit performance metadata without importing requested target packages.

Run with the application's interpreter. This describes the current process,
not a running service, CPU quota, or native thread pools. No environment
variable values, host name, home path, source, or application args are emitted.
"""

from __future__ import annotations

import argparse
import gc
import importlib.metadata
import json
import os
import platform
import struct
import sys
import sysconfig
import time


def optional_call(owner: object, name: str):
    function = getattr(owner, name, None)
    if not callable(function):
        return None
    try:
        return function()
    except (OSError, RuntimeError, NotImplementedError):
        return None


def capture_environment(packages=()):
    """Return JSON-compatible metadata; null means unknown/unavailable."""
    versions = {}
    for name in sorted(set(packages)):
        try:
            versions[name] = importlib.metadata.version(name)
        except importlib.metadata.PackageNotFoundError:
            versions[name] = None

    affinity_count = None
    if hasattr(os, "sched_getaffinity"):
        try:
            affinity_count = len(os.sched_getaffinity(0))
        except (OSError, NotImplementedError):
            pass

    clock = time.get_clock_info("perf_counter")
    jit = getattr(sys, "_jit", None)
    return {
        "schema_version": 1,
        "scope": "current helper process; target packages are not imported",
        "python": {
            "implementation": platform.python_implementation(),
            "version": platform.python_version(),
            "compiler": platform.python_compiler(),
            "build": list(platform.python_build()),
            "pointer_bits": struct.calcsize("P") * 8,
            "py_debug": sysconfig.get_config_var("Py_DEBUG"),
            "free_threaded_build": sysconfig.get_config_var("Py_GIL_DISABLED"),
            "gil_enabled_now": optional_call(sys, "_is_gil_enabled"),
            "jit_available": optional_call(jit, "is_available"),
            "jit_enabled": optional_call(jit, "is_enabled"),
            "optimization_level": sys.flags.optimize,
            "dev_mode": sys.flags.dev_mode,
            "hash_randomization": sys.flags.hash_randomization,
        },
        "platform": {
            "system": platform.system(),
            "release": platform.release(),
            "machine": platform.machine(),
        },
        "cpu": {
            "logical_count": os.cpu_count(),
            "process_count": optional_call(os, "process_cpu_count"),
            "affinity_count": affinity_count,
            "quota": "record deployment CPU quota separately",
        },
        "gc": {"enabled": gc.isenabled(), "thresholds": list(gc.get_threshold())},
        "perf_counter": {
            "implementation": clock.implementation,
            "resolution_seconds": clock.resolution,
            "monotonic": clock.monotonic,
            "adjustable": clock.adjustable,
        },
        "packages": versions,
        "record_separately": [
            "application revision, workload and input identity",
            "container CPU quota and memory limit",
            "worker counts and native thread-pool configuration",
            "GIL state after application extensions are imported",
            "relevant runtime settings, cache state and benchmark command",
        ],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--package", action="append", default=[], metavar="DISTRIBUTION",
        help="record this installed distribution's version; repeat as needed",
    )
    args = parser.parse_args()
    print(json.dumps(capture_environment(args.package), indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
