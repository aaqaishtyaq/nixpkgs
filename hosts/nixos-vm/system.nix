{ lib, pkgs, ... }:

{
  boot.isContainer = true;
  programs.zsh.enable = true;

  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "mode=755" ];
  };

  users.users.aaqa = {
    isNormalUser = true;
    home = "/home/aaqa";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  networking.useDHCP = lib.mkDefault true;
}
