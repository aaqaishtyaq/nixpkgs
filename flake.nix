{
  description = "Aaqa's darwin system";

  inputs = {
    # Package sets
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Environment/system management
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    flake-utils.url = "github:numtide/flake-utils";

    comma = {
      url = "github:nix-community/comma";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      self,
      darwin,
      nixpkgs,
      home-manager,
      flake-utils,
      mac-app-util,
      ...
    }@inputs:
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
        overlays =
          attrValues self.overlays
          ++ singleton (
            final: prev:
            (optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
              # Sub in x86 version of packages that don't build on Apple Silicon.
              # inherit (final.pkgs-x86) [...];
            })
            // {
              # Add other overlays here if needed.
            }
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
            inherit (prev.stdenv) system;
            inherit (nixpkgsDefaults) config;
          };
        };
        pkgs-stable = _: prev: {
          pkgs-stable = import inputs.nixpkgs-stable {
            inherit (prev.stdenv) system;
            inherit (nixpkgsDefaults) config;
          };
        };
        pkgs-unstable = _: prev: {
          pkgs-unstable = import inputs.nixpkgs-unstable {
            inherit (prev.stdenv) system;
            inherit (nixpkgsDefaults) config;
          };
        };
        apple-silicon =
          _: prev:
          optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
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

        home-user-info =
          { lib, ... }:
          {
            options.home.user-info =
              (self.darwinModules.users-primaryUser { inherit lib; }).options.users.primaryUser;
          };
      };

      darwinConfigurations = {
        # minimal macOS configurations to bootstrap system
        bootstrap-x86 = makeOverridable darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = [
            ./darwin/bootstrap.nix
            { nixpkgs = nixpkgsDefaults; }
          ];
        };
        bootstrap-arm = self.darwinConfigurations.bootstrap-x86.override {
          system = "aarch64-darwin";
        };

        # My Apple Silicon macOS laptop config
        m4-pro = makeOverridable self.lib.mkDarwinSystem (
          primaryUserDefaults
          // {
            modules =
              attrValues self.darwinModules
              ++ singleton {
                nixpkgs = nixpkgsDefaults;
                networking.computerName = "powerbook";
                networking.hostName = "powerbook";
                networking.knownNetworkServices = [
                  "Wi-Fi"
                  "USB 10/100/1000 LAN"
                ];
                system.primaryUser = "aaqa"; # Add this line for the new nix-darwin requirement
                nix.registry.my.flake = inputs.self;
              };
            inherit homeStateVersion;
            homeModules = attrValues self.homeManagerModules ++ [
              inputs.mac-app-util.homeManagerModules.default
            ];
          }
        );

        # Config with small modifications needed/desired for CI with GitHub workflow
        githubCI = self.darwinConfigurations.m4-pro.override {
          username = "runner";
          nixConfigDirectory = "/Users/runner/work/nixpkgs/nixpkgs";
          extraModules = singleton {
            environment.etc.shells.enable = mkForce false;
            environment.etc."nix/nix.conf".enable = mkForce false;
            homebrew.enable = mkForce false;
            # TODO: Remove when VM on GitHub updates to Sonoma
            ids.uids.nixbld = 300;
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
        homeConfigurations.runner = self.homeConfigurations.malo.override (old: {
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
        devShells =
          let
            pkgs = self.legacyPackages.${system};
          in
          {
            default = pkgs.mkShell {
              name = "default";
              buildInputs = attrValues { inherit (pkgs) nixd nixfmt-rfc-style; };
            };
            python = pkgs.mkShell {
              name = "python310";
              inputsFrom = attrValues {
                inherit (pkgs.pkgs-master.python310Packages)
                  black
                  isort
                  certbot
                  psycopg2
                  ;
                inherit (pkgs)
                  poetry
                  python310
                  pyright
                  bigquery-schema-generatori
                  ;
              };
            };
          };
        # }}}
      });
    };
}
