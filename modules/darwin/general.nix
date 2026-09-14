{ pkgs, ... }:

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

  # Networking
  networking.dns = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  # Apps
  # `home-manager` currently has issues adding them to `~/Applications`
  # Issue: https://github.com/nix-community/home-manager/issues/1341
  environment.systemPackages = with pkgs; [
    terminal-notifier
  ];
  programs.nix-index.enable = true;

  # Keyboard
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;

  # Store management
  nix = {
    gc = {
      automatic = true;
      interval.Hour = 3;
      options = "--delete-older-than 15d";
    };
    optimise = {
      automatic = true;
      interval.Hour = 4;
    };
  };
}
