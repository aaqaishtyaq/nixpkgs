{ ... }:
{
  aaqa = {
    gui.enable = true;

    zsh.enable = true;
    zsh.extraSessionVariables = {
      IAY_DISABLE_VCS = "1";
      IAY_CWD_HOME_COLOR = "magenta";
      IAY_SHORTEN_CWD = "0";
      IAY_EXPAND_TILDE = "1";
    };
    tmux.enable = true;
    nvim.enable = true;
    alacritty.enable = false;
    ghostty.enable = true;
    hammerspoon.enable = false;
  };
}
