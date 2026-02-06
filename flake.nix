{
  description = "Aaqa's darwin system";

  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/master";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Environment/system management
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Flake utilities
    flake-utils.url = "github:numtide/flake-utils";

    comma = {
      url = "github:nix-community/comma";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = { self, darwin, nixpkgs, home-manager, flake-utils, ... }@inputs:
    let
      inherit (darwin.lib) darwinSystem;
      inherit (inputs.nixpkgs-unstable.lib)
        attrValues
        makeOverridable
        optionalAttrs
        singleton
        mkForce
        ;

      homeStateVersion = "25.05";

      primaryUserDefaults = {
        username = "aaqa";
        fullName = "aaqa";
        email = "aaqaishtyaq@gmail.com";
        nixConfigDirectory = "/Users/aaqa/.config/nixpkgs";
        homeDirectory = "/Users/aaqa";
      };

      nixpkgsDefaults = {
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "ruby-2.7.8"
            "openssl-1.1.1u"
            "openssl-1.1.1w"
            "nodejs-16.20.0"
            "python-2.7.18.7"
          ];
        };
        overlays = attrValues self.overlays ++ singleton (
          # Sub in x86 version of packages that don't build on Apple Silicon yet
          final: prev: (optionalAttrs (prev.stdenv.hostPlatform.system == "aarch64-darwin")
            {
              inherit (final.pkgs-x86)
              nix-index;
            }
          )
        );
      };
    in
    {
      # Add some additional functions to `lib`.
      lib = inputs.nixpkgs-unstable.lib.extend (
        _: _: {
          mkDarwinSystem = import ./lib/mkDarwinSystem.nix inputs;
        }
      );

      # Overlays --------------------------------------------------------------------------------{{{

      overlays = {
        # Overlays to add different versions `nixpkgs` into package set
        pkgs-master = _: prev: {
          pkgs-master = import inputs.nixpkgs-master {
            inherit (prev.stdenv.hostPlatform) system;
            inherit (nixpkgsDefaults) config;
          };
        };
        pkgs-stable = _: prev: {
          pkgs-stable = import inputs.nixpkgs-stable {
            inherit (prev.stdenv.hostPlatform) system;
            inherit (nixpkgsDefaults) config;
          };
        };
        pkgs-unstable = _: prev: {
          pkgs-unstable = import inputs.nixpkgs-unstable {
            inherit (prev.stdenv.hostPlatform) system;
            inherit (nixpkgsDefaults) config;
          };
        };
        apple-silicon = _: prev: optionalAttrs (prev.stdenv.hostPlatform.system == "aarch64-darwin") {
          # Add access to x86 packages system is running Apple Silicon
          pkgs-x86 = import inputs.nixpkgs-unstable {
            system = "x86_64-darwin";
            inherit (nixpkgsDefaults) config;
          };
        };
      };

      darwinModules = {
        # My configurations
        darwin-bootstrap = import ./darwin/bootstrap.nix;
        darwin-general = import ./darwin/general.nix;
        darwin-homebrew = import ./darwin/homebrew.nix;
        darwin-pam = import ./darwin/pam.nix;

        users-primaryUser = import ./modules/darwin/users.nix;
      };

      homeManagerModules = {
        # My configurations
        darwin-home = import ./home;

        home-user-info = { lib, ... }: {
          options.home.user-info = lib.mkOption {
            type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
          };
        };
      };

      darwinConfigurations = {
        # minimal macOS configurations to bootstrap system
        bootstrap-arm = makeOverridable darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [ ./darwin/bootstrap.nix { nixpkgs = nixpkgsDefaults; } ];
        };

        # My apple silicon macOS work laptop
        m4-pro = makeOverridable self.lib.mkDarwinSystem (primaryUserDefaults // {
          modules = attrValues self.darwinModules ++ singleton {
            nixpkgs = nixpkgsDefaults;
            networking.computerName = "powerbook";
            networking.hostName = "powerbook";
            networking.knownNetworkServices = [
              "Wi-Fi"
              "USB 10/100/1000 LAN"
            ];
            nix.registry.my.flake = inputs.self;
          };
          inherit homeStateVersion;
          homeModules = attrValues self.homeManagerModules;
        });

        githubCI = self.darwinConfigurations.m4-pro.override {
          username = "runner";
          nixConfigDirectory = "/Users/runner/work/nixpkgs/nixpkgs";
          extraModules = singleton {
            environment.etc.shells.enable = mkForce false;
            environment.etc."nix/nix.conf".enable = mkForce false;
            homebrew.enable = mkForce false;
          };
        };
      };

      # Config I use with non-NixOS Linux systems (e.g., cloud VMs etc.)
      # Build and activate on new system with:
      # `nix build .#homeConfigurations.aaqa.activationPackage && ./result/activate`
      homeConfigurations.aaqa = makeOverridable home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs-unstable (nixpkgsDefaults // { system = "x86_64-linux"; });
        modules =
          attrValues self.homeManagerModules
          ++ singleton (
            { config, ... }:
            {
              home.username = config.home.user-info.username;
              home.homeDirectory = "/home/${config.home.username}";
              home.stateVersion = homeStateVersion;
              home.user-info = primaryUserDefaults // {
                nixConfigDirectory = "${config.home.homeDirectory}/.config/nixpkgs";
              };
            }
          );
      };

      # Config with small modifications needed/desired for CI with GitHub workflow
      homeConfigurations.runner = self.homeConfigurations.aaqa.override (old: {
        modules =
          old.modules
          ++ singleton {
            home.username = mkForce "runner";
            home.homeDirectory = mkForce "/home/runner";
            home.user-info.nixConfigDirectory = mkForce "/home/runner/work/nixpkgs/nixpkgs";
          };
      });
    }
    // flake-utils.lib.eachDefaultSystem (system: {
      # Re-export `nixpkgs-unstable` with overlays.
      # This is handy in combination with setting `nix.registry.my.flake = inputs.self`.
      # Allows doing things like `nix run my#prefmanager -- watch --all`
      legacyPackages = import inputs.nixpkgs-unstable (nixpkgsDefaults // { inherit system; });

      # Development shells ----------------------------------------------------------------------{{{
      # Shell environments for development
      # With `nix.registry.my.flake = inputs.self`, development shells can be created by running,
      # e.g., `nix develop my#python`.
      devShells = let pkgs = self.legacyPackages.${system}; in
        {
          python = pkgs.mkShell {
            name = "python310";
            inputsFrom = attrValues {
              inherit (pkgs.pkgs-master.python310Packages) black isort certbot psycopg2;
              inherit (pkgs) poetry python310 pyright bigquery-schema-generatori;
            };
          };
        };
      # }}}
    });
}
