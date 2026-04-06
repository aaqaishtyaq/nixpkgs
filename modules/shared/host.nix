{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.aaqa.host = {
    name = mkOption {
      type = with types; nullOr str;
      default = null;
    };
    kind = mkOption {
      type = with types; nullOr (enum [
        "darwin"
        "home"
        "nixos"
      ]);
      default = null;
    };
    system = mkOption {
      type = with types; nullOr str;
      default = null;
    };
    hostname = mkOption {
      type = with types; nullOr str;
      default = null;
    };
    roles = mkOption {
      type = with types; listOf str;
      default = [ ];
    };
    features = mkOption {
      type = with types; attrsOf bool;
      default = { };
    };
  };
}
