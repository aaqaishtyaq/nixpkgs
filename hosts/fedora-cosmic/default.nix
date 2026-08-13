{
  kind = "home";
  system = "x86_64-linux";
  hostname = "fedora-cosmic";
  roles = [ "desktop" ];
  extraHomeModules = [ ../linux-desktop-home.nix ];
}
