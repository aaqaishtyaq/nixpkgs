{ config, pkgs, ... }: {
  imports = [
    ./packages.nix
    ./zsh/default.nix
    ./tmux/default.nix
    ./nvim/default.nix
    ./alacritty/default.nix
    ./ghostty/default.nix
    ./hammerspoon/default.nix
  ];

  aaqaishtyaq = {
    zsh.enable = true;
    tmux.enable = true;
    nvim.enable = true;
    alacritty.enable = true;
    ghostty.enable = true;
    hammerspoon.enable = true;
  };
}
