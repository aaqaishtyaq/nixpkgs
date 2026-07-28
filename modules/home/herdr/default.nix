{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.aaqa.herdr;
in
{
  options.aaqa.herdr = {
    enable = mkEnableOption "set up herdr (tmux-aligned keybindings)";
  };

  config = mkIf cfg.enable {
    xdg.configFile."herdr/config.toml".source = ./config.toml;
  };
}
