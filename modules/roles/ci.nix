{
  config,
  lib,
  ...
}:

{
  options.aaqa.roles.ci.enable = lib.mkEnableOption "Mark this host as CI";

  config = lib.mkIf config.aaqa.roles.ci.enable { };
}
