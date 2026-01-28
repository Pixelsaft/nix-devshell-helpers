# Nix Devshell Helpers

Helper scripts and templates for Nix development shells.

## Quick Start

Copy [`flake.example.nix`](./flake.example.nix) to your project as `flake.nix` and run `nix develop`.

## Multi-system support

Hardcoding `x86_64-linux` limits portability. Use `nixpkgs.lib.genAttrs` for multi-system support:

```nix
outputs = { nixpkgs, nix-devshell-helpers, ... }: let
  forAllSystems = nixpkgs.lib.genAttrs [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];
in {
  devShells = forAllSystems (system: let
    pkgs = nixpkgs.legacyPackages.${system};
    # ... rest of config
  in {
    default = pkgs.mkShell { ... };
  });
};
```

## Pin nixpkgs for reproducibility

Using `nixos-unstable` can lead to different environments over time. Consider:

- **Using a stable release**: `github:NixOS/nixpkgs/nixos-24.11`
- **Pinning to a specific commit**: `github:NixOS/nixpkgs/abc123...`

The `flake.lock` file pins the exact version, but updating the lock file will pull newer packages from unstable.

## PHP-FPM

Manages PHP-FPM lifecycle in development shells with automatic socket configuration.

### Scripts

- `php-fpm/start-php-fpm.sh` - Starts PHP-FPM
- `php-fpm/stop-php-fpm.sh` - Stops PHP-FPM and cleans up
- `php-fpm/add-php-fpm-handler-to-htaccess.sh` - Configures Apache .htaccess
- `php-fpm/remove-php-fpm-handler-from-htaccess.sh` - Removes .htaccess configuration

### Configuration

**Required:**

- `PROJECT_HTACCESS_PATH` - Path to .htaccess (only if using htaccess scripts)

**Optional (auto-detected with sensible defaults):**

- `PHP_FPM_BIN` - Path to php-fpm binary (defaults to `php-fpm` in PATH)
- `PHP_FPM_POOL_NAME` - Pool name (defaults to current directory name)
- `PHP_FPM_RUNTIME_DIR` - Runtime directory (defaults to `$XDG_RUNTIME_DIR/<pool-name>` on Linux, `$TMPDIR/<pool-name>` on macOS, or `/tmp/<pool-name>` as fallback)
- `PHP_FPM_SOCKET_PATH` - Socket path (defaults to `$PHP_FPM_RUNTIME_DIR/php-fpm.sock`)

### Features

- **Auto-detection**: Sensible defaults for pool name, runtime directory, and socket path
- **Mailpit integration**: Automatically configures `sendmail_path` if [mailpit](https://github.com/axllent/mailpit) is available in PATH
- **Per-directory configuration**: Supports `.user.ini` files for overriding PHP settings per project (instant updates in dev mode)
- **Cross-platform**: Uses `$XDG_RUNTIME_DIR` on Linux, `$TMPDIR` on macOS, with `/tmp` fallback
- **Graceful cleanup**: Kills orphaned processes and removes runtime directories on exit

### Usage

```nix
{
  description = "Development environment with PHP-FPM";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nix-devshell-helpers = {
      url = "github:timohubois/nix-devshell-helpers";
      flake = false;
    };
  };

  outputs = { nixpkgs, nix-devshell-helpers, ... }: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  in {
    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        packages = [ pkgs.php83 ];

        shellHook = ''
          export PHP_FPM_BIN="${pkgs.php83}/bin/php-fpm"
          source ${nix-devshell-helpers}/php-fpm/start-php-fpm.sh

          # Apache htaccess handler - uncomment to enable
          # export PROJECT_HTACCESS_PATH="$PWD/static/.htaccess"
          [ -n "$PROJECT_HTACCESS_PATH" ] && source ${nix-devshell-helpers}/php-fpm/add-php-fpm-handler-to-htaccess.sh

          cleanup() {
            source ${nix-devshell-helpers}/php-fpm/stop-php-fpm.sh
            [ -n "$PROJECT_HTACCESS_PATH" ] && source ${nix-devshell-helpers}/php-fpm/remove-php-fpm-handler-from-htaccess.sh
          }
          trap cleanup EXIT
        '';
      };
    });
  };
}
```
