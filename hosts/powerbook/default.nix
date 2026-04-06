{
  kind = "darwin";
  system = "aarch64-darwin";
  hostname = "powerbook";
  roles = [
    "desktop"
    "laptop"
  ];
  extraModules = [ ./system.nix ];
}
