{
  description = "Development environment with PHP (FPM and CLI) and Node";

  inputs = {
    # Pin to stable release for reproducibility
    # Use nixos-unstable for latest packages: github:NixOS/nixpkgs/nixos-unstable
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nix-devshell-helpers = {
      url = "github:pixelsaft/nix-devshell-helpers";
      flake = false;
    };
  };

  outputs = { nixpkgs, nix-devshell-helpers, ... }: let
    # Multi-system support
    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  in {
    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      php = pkgs.php83.buildEnv {
        extensions = { enabled, all }: enabled ++ (with all; [
          imagick
          xdebug
        ]);
      };

      nodejs = pkgs.nodejs_22;

    in {
      default = pkgs.mkShell {
        packages = [
          php
          nodejs
        ];

        shellHook = ''
          # PHP-FPM (explicitly set PHP version, recommended for reproducibility)
          export PHP_FPM_BIN="${php}/bin/php-fpm"
          source ${nix-devshell-helpers}/php-fpm/start-php-fpm.sh

          # Apache/.htaccess configuration (optional)
          export PROJECT_HTACCESS_PATH="$PWD/static/.htaccess"
          source ${nix-devshell-helpers}/php-fpm/add-php-fpm-handler-to-htaccess.sh

          echo "PHP: $(php --version | head -1)"
          echo "Node: $(node --version)"

          # Cleanup on exit
          cleanup() {
            source ${nix-devshell-helpers}/php-fpm/stop-php-fpm.sh
            source ${nix-devshell-helpers}/php-fpm/remove-php-fpm-handler-from-htaccess.sh
          }
          trap cleanup EXIT
        '';
      };
    });
  };
}
