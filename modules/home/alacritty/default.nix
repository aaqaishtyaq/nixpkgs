{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.aaqa.alacritty;
in
{
  options.aaqa.alacritty = {
    enable = mkEnableOption "Enable alacritty terminal";
  };
  config = mkIf cfg.enable {
    home.file = {
      ".config/alacritty/themes/default.toml".source = ./default_theme.toml;
      ".config/alacritty/config.toml".source = ./alacritty.toml;
    };
  };
}
