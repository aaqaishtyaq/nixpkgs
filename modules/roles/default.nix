{ ... }:

{
  imports = [
    ./desktop.nix
    ./server.nix
    ./laptop.nix
    ./vm.nix
    ./ci.nix
  ];
}
