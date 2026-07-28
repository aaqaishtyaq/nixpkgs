{ ... }:
{
  imports = [
    ../shared/host.nix
    ../shared/home-user-info.nix
    ../roles
    ./packages.nix
    ./git/default.nix
    ./zsh/default.nix
    ./tmux/default.nix
    ./herdr/default.nix
    ./nvim/default.nix
    ./alacritty/default.nix
    ./ghostty/default.nix
    ./hammerspoon/default.nix
    ./dircolors/default.nix
  ];
}
