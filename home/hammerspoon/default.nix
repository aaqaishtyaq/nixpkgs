{config, lib, pkgs, ...}:

with lib;

let
  cfg = config.aaqaishtyaq.hammerspoon;
in {
  options.aaqaishtyaq.hammerspoon = {
    enable = mkEnableOption "Enable hammerspoon configurations";
  };
  config = mkIf cfg.enable {
    home.file = {
      ".hammerspoon/init.lua".source = ./init.lua;
      ".hammerspoon/window-management.lua".source = ./window-management.lua;
    };
  };
}
