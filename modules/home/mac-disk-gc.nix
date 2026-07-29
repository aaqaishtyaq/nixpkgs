{
  config,
  lib,
  pkgs,
  ...
}:

let
  script = ./bin/mac-disk-gc.sh;
in
{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    home.file.".local/bin/mac-disk-gc.sh".source = script;

    launchd.agents.mac-disk-gc = {
      enable = true;
      config = {
        ProgramArguments = [
          "/bin/bash"
          "${config.home.homeDirectory}/.local/bin/mac-disk-gc.sh"
        ];
        StartCalendarInterval = [
          {
            Weekday = 1;
            Hour = 10;
            Minute = 0;
          }
        ];
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/mac-disk-gc.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/mac-disk-gc.log";
        RunAtLoad = false;
      };
    };
  };
}
