{ pkgs, ... }:

{
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
