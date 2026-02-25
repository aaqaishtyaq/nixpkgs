{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.aaqa.hammerspoon;
in
{
  options.aaqa.hammerspoon = {
    enable = mkEnableOption "Enable hammerspoon configurations";
  };
  config = mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.file = {
      ".hammerspoon/init.lua".source = ./init.lua;
      ".hammerspoon/window-management.lua".source = ./window-management.lua;
    };
  };
}
