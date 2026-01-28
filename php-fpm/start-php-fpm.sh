#!/usr/bin/env bash
# Start PHP-FPM for development environment

# Auto-detect PHP-FPM binary if not set
if [ -z "$PHP_FPM_BIN" ]; then
  if command -v php-fpm &> /dev/null; then
    PHP_FPM_BIN="$(command -v php-fpm)"
  else
    echo "ERROR: PHP_FPM_BIN not set and php-fpm not found in PATH"
    echo "Set PHP_FPM_BIN to your php-fpm binary path"
    return 1
  fi
fi

# Optional: Auto-detect with sensible defaults
PHP_FPM_POOL_NAME="${PHP_FPM_POOL_NAME:-$(basename "$PWD")}"
PHP_FPM_RUNTIME_DIR="${PHP_FPM_RUNTIME_DIR:-${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/$PHP_FPM_POOL_NAME}"
PHP_FPM_SOCKET_PATH="${PHP_FPM_SOCKET_PATH:-$PHP_FPM_RUNTIME_DIR/php-fpm.sock}"

export PHP_FPM_POOL_NAME PHP_FPM_RUNTIME_DIR PHP_FPM_SOCKET_PATH

# Determine script directory to find template files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Clean up any orphaned processes from previous sessions
if [ -f "$PHP_FPM_RUNTIME_DIR/php-fpm.pid" ]; then
  OLD_PID="$(cat "$PHP_FPM_RUNTIME_DIR/php-fpm.pid")"
  if kill -0 "$OLD_PID" 2>/dev/null; then
    kill "$OLD_PID" 2>/dev/null
    sleep 0.5
  fi
fi

# Create run directory
mkdir -p "$PHP_FPM_RUNTIME_DIR"

# Copy php.ini template
PHP_INI="$PHP_FPM_RUNTIME_DIR/php.ini"
cp "$SCRIPT_DIR/php.ini.template" "$PHP_INI"
chmod +w "$PHP_INI"

# Add mailpit sendmail path if mailpit is available
if command -v mailpit &> /dev/null; then
  {
    echo ""
    echo "; Mailpit configuration"
    echo "sendmail_path = $(which mailpit) sendmail -t"
  } >> "$PHP_INI"
fi

# Generate PHP-FPM config from template (bash handles ${VAR} substitution)
PHP_FPM_CONF="$PHP_FPM_RUNTIME_DIR/php-fpm.conf"
eval "cat <<EOF
$(cat "$SCRIPT_DIR/php-fpm.conf.template")
EOF" > "$PHP_FPM_CONF"
export PHP_FPM_CONF

# Start PHP-FPM with custom php.ini
rm -f "$PHP_FPM_SOCKET_PATH"
"$PHP_FPM_BIN" -c "$PHP_INI" --nodaemonize --fpm-config "$PHP_FPM_CONF" & PHP_FPM_PID=$!
export PHP_FPM_PID
echo "$PHP_FPM_PID" > "$PHP_FPM_RUNTIME_DIR/php-fpm.pid"

# Wait for socket
for _ in {1..30}; do
  [ -S "$PHP_FPM_SOCKET_PATH" ] && break
  sleep 0.1
done

if [ ! -S "$PHP_FPM_SOCKET_PATH" ]; then
  echo "ERROR: Socket not created at $PHP_FPM_SOCKET_PATH"
  return 1
fi

echo "php-fpm socket location: $PHP_FPM_SOCKET_PATH"
