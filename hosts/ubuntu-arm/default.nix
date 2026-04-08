{
  kind = "home";
  system = "aarch64-linux";
  hostname = "ubuntu-arm";
  roles = [
    "desktop"
    "vm"
  ];
  extraHomeModules = [ ../linux-desktop-home.nix ];
}
