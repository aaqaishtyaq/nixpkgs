inputs:
{
  host,
  nixpkgsDefaults,
}:

let
  lib = inputs.nixpkgs-unstable.lib;
  inherit (lib) optionalAttrs;
  darwinModule = import ../modules/darwin;
  homeManagerModule = import ../modules/home;
  nixosModule = import ../modules/nixos;
  mergeModules = modules: lib.foldl' lib.recursiveUpdate { } modules;

  baseHomeModule =
    { ... }:
    lib.mkMerge [
      {
        home.username = host.username;
        home.homeDirectory = host.homeDirectory;
        home.stateVersion = host.homeStateVersion;
        home.user-info = {
          inherit (host)
            username
            fullName
            email
            homeDirectory
            nixConfigDirectory
            ;
        };
      }
      (lib.mkIf (host.kind == "home") {
        home.file.".config/nix/nix.conf".text = ''
          experimental-features = nix-command flakes
        '';
      })
    ];

  hostHomeModule =
    { ... }:
    mergeModules (
      [
        {
          aaqa.host = {
            inherit (host)
              name
              kind
              system
              hostname
              roles
              features
              ;
          };
        }
      ]
      ++ map (role: lib.setAttrByPath [ "aaqa" "roles" role "enable" ] true) host.roles
      ++ map
        (feature: lib.setAttrByPath [ "aaqa" feature "enable" ] host.features.${feature})
        (builtins.attrNames host.features)
    );

  nixRegistryModule = {
    nix.registry.my.flake = inputs.self;
  };

  darwinUserModule =
    { config, ... }:
    {
      users.primaryUser = {
        inherit (host)
          username
          fullName
          email
          nixConfigDirectory
          homeDirectory
          ;
      };

      system.primaryUser = host.username;
      users.users.${host.username}.home = host.homeDirectory;
      nix.nixPath.nixpkgs = "${inputs.nixpkgs-unstable}";

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${host.username} = {
        imports = [
          homeManagerModule
          baseHomeModule
          hostHomeModule
        ] ++ host.extraHomeModules;
      };
    };

  nixosUserModule =
    { ... }:
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${host.username} = {
        imports = [
          homeManagerModule
          baseHomeModule
          hostHomeModule
        ] ++ host.extraHomeModules;
      };
    };
in
if host.kind == "darwin" then
  inputs.darwin.lib.darwinSystem {
    system = host.system;
    modules = [
      darwinModule
      inputs.home-manager.darwinModules.home-manager
      nixRegistryModule
      { nixpkgs = nixpkgsDefaults; }
      {
        aaqa.host = {
          inherit (host)
            name
            kind
            system
            hostname
            roles
            features
            ;
        };
      }
      darwinUserModule
    ] ++ host.extraModules;
  }
else if host.kind == "nixos" then
  inputs.nixpkgs-unstable.lib.nixosSystem {
    system = host.system;
    modules = [
      nixosModule
      inputs.home-manager.nixosModules.home-manager
      nixRegistryModule
      { nixpkgs = nixpkgsDefaults; }
      {
        system.stateVersion = host.stateVersion;
        aaqa.host = {
          inherit (host)
            name
            kind
            system
            hostname
            roles
            features
            ;
        };
      }
      nixosUserModule
    ] ++ host.extraModules;
  }
else
  inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs-unstable (nixpkgsDefaults // { system = host.system; });
    modules = [
      homeManagerModule
      baseHomeModule
      hostHomeModule
    ] ++ host.extraHomeModules;
  }
