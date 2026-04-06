{ config, lib, ... }:

{
  config = lib.mkIf (config.aaqa.host.hostname != null) {
    networking.hostName = lib.mkDefault config.aaqa.host.hostname;
  };
}
