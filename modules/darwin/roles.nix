{ config, lib, ... }:

let
  hasRole = role: builtins.elem role config.aaqa.host.roles;
in
{
  config = lib.mkMerge [
    (lib.mkIf (config.aaqa.host.hostname != null) {
      networking.hostName = lib.mkDefault config.aaqa.host.hostname;
      networking.computerName = lib.mkDefault config.aaqa.host.hostname;
    })
    (lib.mkIf (hasRole "ci") {
      environment.etc.shells.enable = lib.mkForce false;
      environment.etc."nix/nix.conf".enable = lib.mkForce false;
      homebrew.enable = lib.mkForce false;
    })
  ];
}
