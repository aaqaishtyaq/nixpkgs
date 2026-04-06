{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.aaqa.roles.laptop;
in
{
  options.aaqa.roles.laptop.enable = lib.mkEnableOption "Enable laptop defaults";

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        aaqa.ghostty.enable = lib.mkDefault true;
      }
      (lib.mkIf pkgs.stdenv.isDarwin {
        aaqa.hammerspoon.enable = lib.mkDefault true;
      })
    ]
  );
}
