{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkDefault mkIf elem;
  caskPresent = cask: lib.any (x: x.name == cask) config.homebrew.casks;
  brewEnabled = config.homebrew.enable;
  homePackages = config.home-manager.users.${config.users.primaryUser.username}.home.packages;
  pinentry-program = "${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac";
in

{
  environment.shellInit = mkIf brewEnabled ''
    eval "$(${config.homebrew.brewPrefix}/brew shellenv)"
  '';

  homebrew.enable = mkDefault true;
  homebrew.onActivation.upgrade = true;
  homebrew.onActivation.cleanup = "zap";
  homebrew.global.brewfile = true;

  homebrew.taps = [
    "homebrew/services"
    "aaqaishtyaq/tap"
  ];

  homebrew.brews = [
    "beads"
    "dnsmasq"
    "herdr"
    "opencode"
    "rtk"
    "stripe"
  ];

  # If an app isn't available in the Mac App Store, or the version in the App Store has
  # limitiations, e.g., Transmit, install the Homebrew Cask.
  homebrew.casks = [
    "hammerspoon"
    "visual-studio-code"
    "utm"
    "hiddenbar"
    "font-blex-mono-nerd-font"
    "font-iosevka-nerd-font"
    "orbstack"
    "zen"
    "alfred"
    "clipy"
    "brave-browser"
    "tailscale-app"
    "rectangle"
    "ghostty"
    "logseq"
    "cursor"
    "vlc"
    "iina"
    "transmission"
    "ollama-app"
    "zed"
    "codex"
    "codex-app"
    "claude-code"
    "claude"
  ];

  home-manager.sharedModules = [
    {
      home.file = {
        gpg-agent = {
          target = ".gnupg/gpg-agent.conf";
          text = ''
            pinentry-program ${pinentry-program}
            default-cache-ttl 43200
            default-cache-ttl-ssh 43200
            max-cache-ttl 43200
            max-cache-ttl-ssh 43200
          '';
        };
      };
    }
  ];
}
