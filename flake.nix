{
  description = "Aaqa's systems";

  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/master";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    iay = {
      url = "github:aaqaishtyaq/iay/v0.5.1";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

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

    # Helium browser isn't in nixpkgs yet; use a community flake until it lands.
    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      self,
      flake-utils,
      ...
    }@inputs:
    let
      lib = inputs.nixpkgs-unstable.lib;
      inherit (lib)
        attrValues
        filterAttrs
        genAttrs
        mapAttrs
        optionalAttrs
        ;

      defaults = {
        homeStateVersion = "25.05";
        darwinStateVersion = 5;
        nixosStateVersion = "25.05";
      };

      primaryUserDefaults = {
        username = "aaqa";
        fullName = "Aaqa Ishtyaq";
        email = "aaqaishtyaq@gmail.com";
      };

      overlays = {
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
        iay = _: prev: {
          iay = inputs.iay.packages.${prev.stdenv.hostPlatform.system}.default;
        };
        helium =
          _: prev:
          optionalAttrs (builtins.elem prev.stdenv.hostPlatform.system [ "x86_64-linux" "aarch64-linux" ]) {
            helium = inputs.helium.packages.${prev.stdenv.hostPlatform.system}.default;
          };
        darwin-python-workarounds =
          _: prev:
          optionalAttrs prev.stdenv.isDarwin {
            python313Packages = prev.python313Packages.overrideScope (
              _: pyPrev: {
                jeepney = pyPrev.jeepney.overrideAttrs (_: {
                  installCheckPhase = "true";
                });
              }
            );
            python3Packages = prev.python3Packages.overrideScope (
              _: pyPrev: {
                jeepney = pyPrev.jeepney.overrideAttrs (_: {
                  installCheckPhase = "true";
                });
              }
            );
          };

        # nixpkgs' Darwin cctools/ld (rebuilt against Clang 21's -fstrict-return
        # default) segfaults (Trace/BPT trap: 5) linking terminal-notifier as of
        # ~2026-07-14 nixpkgs-unstable/master. Borrow the binary from the
        # pre-regression nixpkgs-stable snapshot until upstream fixes it.
        # TODO: drop once https://github.com/NixOS/nixpkgs cctools-darwin is fixed.
        darwin-terminal-notifier-workaround =
          final: prev:
          optionalAttrs prev.stdenv.isDarwin {
            terminal-notifier = final.pkgs-stable.terminal-notifier;
          };

        direnv-cgo-fix =
          _: prev:
          optionalAttrs prev.stdenv.isDarwin {
            direnv = prev.direnv.overrideAttrs (old: {
              env = (old.env or { }) // {
                CGO_ENABLED = "1";
              };
            });
          };
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
        overlays = attrValues overlays;
      };

      rawHosts = import ./hosts;

      normalizeHost =
        name: host:
        let
          username = host.username or primaryUserDefaults.username;
          homeDirectory =
            host.homeDirectory or (if host.kind == "darwin" then "/Users/${username}" else "/home/${username}");
        in
        {
          name = name;
          kind = host.kind;
          system = host.system;
          username = username;
          fullName = host.fullName or primaryUserDefaults.fullName;
          email = host.email or primaryUserDefaults.email;
          hostname = host.hostname or name;
          homeDirectory = homeDirectory;
          nixConfigDirectory = host.nixConfigDirectory or "${homeDirectory}/.config/nixpkgs";
          stateVersion =
            host.stateVersion
              or (if host.kind == "darwin" then defaults.darwinStateVersion else defaults.nixosStateVersion);
          homeStateVersion = host.homeStateVersion or defaults.homeStateVersion;
          roles = host.roles or [ ];
          features = host.features or { };
          extraModules = host.extraModules or [ ];
          extraHomeModules = host.extraHomeModules or [ ];
        };

      hosts = mapAttrs normalizeHost rawHosts;

      mkHost = import ./lib/mkHost.nix inputs;
      builtHosts = mapAttrs (_: host: mkHost { inherit host nixpkgsDefaults; }) hosts;

      hostsByKind = kind: filterAttrs (_: host: host.kind == kind) hosts;

      homeHosts = hostsByKind "home";
      darwinHosts = hostsByKind "darwin";
      nixosHosts = hostsByKind "nixos";

      hostDerivation =
        name:
        let
          host = hosts.${name};
          built = builtHosts.${name};
        in
        if host.kind == "home" then
          built.activationPackage
        else if host.kind == "darwin" then
          built.system
        else
          built.config.system.build.toplevel;

      hostDrvPath = name: (hostDerivation name).drvPath;

      representativeHosts = [
        "powerbook"
        "github-macos"
        "linux-vm"
        "ubuntu-arm"
        "nixos-vm"
      ];
    in
    {
      lib = lib.extend (
        _: _: {
          inherit mkHost;
        }
      );

      inherit overlays;

      hosts = hosts;

      darwinModules.default = import ./modules/darwin;
      nixosModules.default = import ./modules/nixos;
      homeManagerModules.default = import ./modules/home;

      roleModules = {
        desktop = import ./modules/roles/desktop.nix;
        server = import ./modules/roles/server.nix;
        laptop = import ./modules/roles/laptop.nix;
        vm = import ./modules/roles/vm.nix;
        ci = import ./modules/roles/ci.nix;
      };

      darwinConfigurations = mapAttrs (name: _: builtHosts.${name}) darwinHosts // {
        bootstrap-arm = inputs.darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./modules/darwin/bootstrap.nix
            { nixpkgs = nixpkgsDefaults; }
          ];
        };

        githubCI = builtHosts.github-macos;
      };

      nixosConfigurations = mapAttrs (name: _: builtHosts.${name}) nixosHosts;

      homeConfigurations = mapAttrs (name: _: builtHosts.${name}) homeHosts // {
        runner = builtHosts.github-linux;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import inputs.nixpkgs-unstable (nixpkgsDefaults // { inherit system; });
        systemHosts = filterAttrs (_: host: host.system == system) hosts;

        mkEvalCheck =
          name:
          pkgs.runCommand "eval-${name}" { } ''
            printf '%s\n' ${lib.escapeShellArg (hostDrvPath name)} > $out
          '';

        representativeChecks = mapAttrs (name: _: hostDerivation name) (
          filterAttrs (name: host: builtins.elem name representativeHosts && host.system == system) hosts
        );
      in
      {
        legacyPackages = pkgs;
        formatter = pkgs.nixfmt;

        checks = genAttrs (builtins.attrNames systemHosts) mkEvalCheck // representativeChecks;

        devShells = {
          python = pkgs.mkShell {
            name = "python314";
            inputsFrom = attrValues {
              inherit (pkgs.pkgs-master.python314Packages)
                black
                isort
                certbot
                psycopg2
                ;
              inherit (pkgs)
                poetry
                python314
                pyright
                ;
            };
          };
        };
      }
    );
}
