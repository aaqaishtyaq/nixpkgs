{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  inherit (lib.generators) toKeyValue mkKeyValueDefault;

  # Convert Alacritty theme format to Ghostty format
  # Based on default_theme.toml from alacritty
  # Uses palette[0] (#1d1f21) for background to match Alacritty's default behavior
  aladarkTheme = ''
    palette = 0=#1d1f21
    palette = 1=#cc6666
    palette = 2=#b5bd68
    palette = 3=#f0c674
    palette = 4=#81a2be
    palette = 5=#b294bb
    palette = 6=#8abeb7
    palette = 7=#c5c8c6
    palette = 8=#666666
    palette = 9=#d54e53
    palette = 10=#b9ca4a
    palette = 11=#e7c547
    palette = 12=#7aa6da
    palette = 13=#c397d8
    palette = 14=#70c0b1
    palette = 15=#eaeaea
    background = #1d1f21
    foreground = #c5c8c6
    cursor-color = #c5c8c6
    cursor-text = #1d1f21
    selection-background = #515151
    selection-foreground = #c5c8c6
  '';

  # Override Cursor Dark theme without selection colors
  cursorDarkCustomTm = ''
    palette = 0=#2a2a2a
    palette = 1=#bf616a
    palette = 2=#a3be8c
    palette = 3=#ebcb8b
    palette = 4=#81a1c1
    palette = 5=#b48ead
    palette = 6=#88c0d0
    palette = 7=#d8dee9
    palette = 8=#505050
    palette = 9=#bf616a
    palette = 10=#a3be8c
    palette = 11=#ebcb8b
    palette = 12=#81a1c1
    palette = 13=#b48ead
    palette = 14=#88c0d0
    palette = 15=#ffffff
    background = #141414
    foreground = #ffffff
    cursor-color = #ffffff
    cursor-text = #141414
    selection-background = cell-foreground
    selection-foreground = cell-background
  '';
in

{
  options.aaqa.ghostty = {
    enable = mkEnableOption "Enable ghostty terminal";
  };

  config = mkIf config.aaqa.ghostty.enable {
    xdg.configFile."ghostty/themes/aladark".text = aladarkTheme;
    xdg.configFile."ghostty/themes/DarkCustom".text = cursorDarkCustomTm;

    xdg.configFile."ghostty/config".text =
      toKeyValue
        {
          mkKeyValue = mkKeyValueDefault { } " = ";
          listsAsDuplicateKeys = true;
        }
        (
          {
            font-size = 18;
            cursor-invert-fg-bg = true;
            cursor-style = "block";
            "shell-integration-features" = "no-cursor";
            font-family = "Berkeley Mono";
            font-feature = "+liga, -calt";
            "confirm-close-surface" = false;
            title = "\" \"";
            font-thicken = true;
            "window-title-font-family" = "Berkeley Mono";
            "window-padding-x" = 10;
            "window-padding-y" = 5;
            "shell-integration" = "zsh";
            "copy-on-select" = "false";
            theme = "DarkCustom";
            bell-features = "no-attention,no-audio,system,no-title,no-border";
            cursor-style-blink = "false";
          }
          // optionalAttrs pkgs.stdenv.isDarwin {
            "macos-titlebar-proxy-icon" = "hidden";
            "window-colorspace" = "display-p3";
          }
        )
      + ''
        keybind = cmd+shift+enter=toggle_fullscreen
      '';

    # Ghostty advertises D-Bus activation.  On generic Linux, systemd does
    # not search the Nix profile's share/systemd/user directory, so expose
    # the packaged unit through Home Manager's normal user-unit path.
    home.file = lib.mkIf pkgs.stdenv.isLinux {
      ".config/systemd/user/app-com.mitchellh.ghostty.service".source =
        "${pkgs.ghostty}/share/systemd/user/app-com.mitchellh.ghostty.service";
    };
  };
}
