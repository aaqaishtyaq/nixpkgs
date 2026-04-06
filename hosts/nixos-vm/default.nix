{
  kind = "nixos";
  system = "x86_64-linux";
  hostname = "nixos-vm";
  roles = [
    "desktop"
    "vm"
  ];
  stateVersion = "25.05";
  extraModules = [ ./system.nix ];
}
