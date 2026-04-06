{
  config,
  lib,
  ...
}:

let
  cfg = config.aaqa.roles.server;
in
{
  options.aaqa.roles.server.enable = lib.mkEnableOption "Enable server defaults";

  config = lib.mkIf cfg.enable {
    aaqa = {
      gui.enable = lib.mkDefault false;

      zsh.enable = lib.mkDefault true;
      tmux.enable = lib.mkDefault true;
      nvim.enable = lib.mkDefault true;
      dircolors.enable = lib.mkDefault true;
      alacritty.enable = lib.mkDefault false;
      ghostty.enable = lib.mkDefault false;
    };
  };
}
