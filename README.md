# Nix Devshell Helpers

Helper scripts and templates for Nix development shells.

## Quick Start

Copy [`flake.example.nix`](./flake.example.nix) to your project as `flake.nix` and run `nix develop`.

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
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-devshell-helpers = {
      url = "github:pixelsaft/nix-devshell-helpers";
      flake = false;
    };
  };

  outputs = { nixpkgs, nix-devshell-helpers, ... }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [ pkgs.php83 ];

      shellHook = ''
        # PHP-FPM (explicitly set PHP version, recommended for reproducibility)
        export PHP_FPM_BIN="${pkgs.php83}/bin/php-fpm"

        source ${nix-devshell-helpers}/php-fpm/start-php-fpm.sh

        cleanup() {
          source ${nix-devshell-helpers}/php-fpm/stop-php-fpm.sh
        }
        trap cleanup EXIT
      '';
    };
  };
}
```
