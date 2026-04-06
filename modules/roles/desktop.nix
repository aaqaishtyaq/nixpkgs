{
  config,
  lib,
  ...
}:

let
  cfg = config.aaqa.roles.desktop;
in
{
  options.aaqa.roles.desktop.enable = lib.mkEnableOption "Enable desktop defaults";

  config = lib.mkIf cfg.enable {
    aaqa = {
      gui.enable = lib.mkDefault true;

      zsh.enable = lib.mkDefault true;
      zsh.extraSessionVariables = {
        IAY_DISABLE_VCS = "1";
        IAY_CWD_HOME_COLOR = "magenta";
        IAY_SHORTEN_CWD = "0";
        IAY_EXPAND_TILDE = "1";
      };
      tmux.enable = lib.mkDefault true;
      nvim.enable = lib.mkDefault true;
      dircolors.enable = lib.mkDefault true;
      alacritty.enable = lib.mkDefault false;
      ghostty.enable = lib.mkDefault true;
    };
  };
}
