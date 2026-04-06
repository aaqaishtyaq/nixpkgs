{
  kind = "home";
  system = "x86_64-linux";
  hostname = "github-linux";
  username = "runner";
  homeDirectory = "/home/runner";
  nixConfigDirectory = "/home/runner/work/nixpkgs/nixpkgs";
  roles = [
    "server"
    "ci"
  ];
}
