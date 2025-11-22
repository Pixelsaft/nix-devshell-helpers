#!/usr/bin/env bash
# Stop PHP-FPM and cleanup

# Optional: Auto-detect with sensible defaults
PHP_FPM_POOL_NAME="${PHP_FPM_POOL_NAME:-$(basename "$PWD")}"
PHP_FPM_RUNTIME_DIR="${PHP_FPM_RUNTIME_DIR:-${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/$PHP_FPM_POOL_NAME}"

[ -n "$PHP_FPM_PID" ] && kill "$PHP_FPM_PID" 2>/dev/null

# Clean up run directory
rm -rf "$PHP_FPM_RUNTIME_DIR"
