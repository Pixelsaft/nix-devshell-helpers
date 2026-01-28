#!/usr/bin/env bash
# Stop PHP-FPM and cleanup

# Optional: Auto-detect with sensible defaults
PHP_FPM_POOL_NAME="${PHP_FPM_POOL_NAME:-$(basename "$PWD")}"
PHP_FPM_RUNTIME_DIR="${PHP_FPM_RUNTIME_DIR:-${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/$PHP_FPM_POOL_NAME}"

# Try to kill using PID variable first, then fall back to PID file
if [ -n "$PHP_FPM_PID" ]; then
  kill "$PHP_FPM_PID" 2>/dev/null
elif [ -f "$PHP_FPM_RUNTIME_DIR/php-fpm.pid" ]; then
  kill "$(cat "$PHP_FPM_RUNTIME_DIR/php-fpm.pid")" 2>/dev/null
fi

# Clean up run directory
rm -rf "$PHP_FPM_RUNTIME_DIR"
