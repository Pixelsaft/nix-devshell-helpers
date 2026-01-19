#!/usr/bin/env bash
# Configure Apache .htaccess for PHP-FPM socket handler

# Required: Path to .htaccess file
: "${PROJECT_HTACCESS_PATH:?PROJECT_HTACCESS_PATH must be set}"

# Optional: Auto-detect with sensible defaults
PHP_FPM_POOL_NAME="${PHP_FPM_POOL_NAME:-$(basename "$PWD")}"
PHP_FPM_RUNTIME_DIR="${PHP_FPM_RUNTIME_DIR:-${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/$PHP_FPM_POOL_NAME}"
PHP_FPM_SOCKET_PATH="${PHP_FPM_SOCKET_PATH:-$PHP_FPM_RUNTIME_DIR/php-fpm.sock}"

if [ ! -f "$PROJECT_HTACCESS_PATH" ]; then
  echo "WARNING: .htaccess not found at $PROJECT_HTACCESS_PATH"
  return
fi

# Resolve symlink if it exists
HTACCESS_TARGET="$(readlink -f "$PROJECT_HTACCESS_PATH")"

# Remove any existing handler
sed -i '/# \[nix develop\] php-fpm socket handler/,/# \[nix develop\] php-fpm socket handler.*END/d' "$HTACCESS_TARGET"

# Add new handler at the beginning
sed -i "1i# [nix develop] php-fpm socket handler - temporary configuration\n<If \"-f '$PHP_FPM_SOCKET_PATH'\">\n  <FilesMatch \\\\.php$>\n    SetHandler \"proxy:unix:$PHP_FPM_SOCKET_PATH|fcgi://localhost\"\n  </FilesMatch>\n</If>\n# [nix develop] php-fpm socket handler END\n" "$HTACCESS_TARGET"

echo "Configured php-fpm socket handler inside $PROJECT_HTACCESS_PATH"
