{
  config,
  lib,
  ...
}:

{
  options.aaqa.roles.vm.enable = lib.mkEnableOption "Mark this host as a VM";

  config = lib.mkIf config.aaqa.roles.vm.enable { };
}
