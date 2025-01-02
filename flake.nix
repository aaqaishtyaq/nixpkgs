{
  description = "Aaqa's darwin system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/master";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url ="github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    comma = {
      url = "github:nix-community/comma";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, darwin, nixpkgs, home-manager, flake-utils, mac-app-util, ... }@inputs:
  let
    home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
    # home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-21.11.tar.gz";
    inherit (darwin.lib) darwinSystem;
    inherit (inputs.nixpkgs-unstable.lib) attrValues makeOverridable optionalAttrs singleton;

    homeStateVersion = "24.11";

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
      overlays = attrValues self.overlays ++ singleton (
        # Sub in x86 version of packages that don't build on Apple Silicon yet
        final: prev: (optionalAttrs (prev.stdenv.system == "aarch64-darwin")
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
      lib = inputs.nixpkgs-unstable.lib.extend (_: _: {
        mkDarwinSystem = import ./lib/mkDarwinSystem.nix inputs;
      });


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
        apple-silicon = _: prev: optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
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

        # setup apps from nix-darwin to show up in spotlight/alfred.
        darwin-spotlight = inputs.mac-app-util.homeManagerModules.default;

        home-user-info = { lib, ... }: {
          options.home.user-info =
            (self.darwinModules.users-primaryUser { inherit lib; }).options.users.primaryUser;
        };
      };

      darwinConfigurations = {
        # minimal macOS configurations to bootstrap system
        bootstrap-arm = makeOverridable darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [ ./darwin/bootstrap.nix { nixpkgs = nixpkgsDefaults; } ];
        };

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

      } // flake-utils.lib.eachDefaultSystem (system: {
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
  };
}
