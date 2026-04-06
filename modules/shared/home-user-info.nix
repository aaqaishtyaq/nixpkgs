{ lib, ... }:

{
  options.home.user-info = lib.mkOption {
    type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
  };
}
