{ ... }:

{
  imports = [
    ../shared/host.nix
    ./bootstrap.nix
    ./general.nix
    ./homebrew.nix
    ./pam.nix
    ./users.nix
    ./roles.nix
  ];
}
