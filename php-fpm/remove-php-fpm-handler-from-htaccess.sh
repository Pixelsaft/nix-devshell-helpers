#!/usr/bin/env bash
# Remove Apache .htaccess PHP-FPM configuration

# Required: Path to .htaccess file
: "${PROJECT_HTACCESS_PATH:?PROJECT_HTACCESS_PATH must be set}"

if [ -f "$PROJECT_HTACCESS_PATH" ]; then
  # Resolve symlink if it exists
  HTACCESS_TARGET="$(readlink -f "$PROJECT_HTACCESS_PATH")"
  sed -i '/# \[nix develop\] php-fpm socket handler/,/# \[nix develop\] php-fpm socket handler.*END/d; /./,$!d' "$HTACCESS_TARGET"
fi
