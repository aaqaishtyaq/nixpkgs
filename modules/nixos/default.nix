{ ... }:

{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://aaqaishtyaq.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "aaqaishtyaq.cachix.org-1:WsgyD6JY1MysNt+5+3oIG/ArOphCzya2lJOyywFcgxA="
    ];
  };

  imports = [
    ../shared/host.nix
    ./roles.nix
  ];
}
