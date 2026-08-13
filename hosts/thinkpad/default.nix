{
  kind = "home";
  system = "x86_64-linux";
  hostname = "thinkpad";
  roles = [ "desktop" ];
  extraHomeModules = [
    ../linux-desktop-home.nix
    (
      { pkgs, ... }:
      {
        home.packages = [ pkgs.gh ];

        # Magenta accent (matches IAY_CWD_HOME_COLOR) so thinkpad sessions
        # are visually distinct from other Linux hosts in tmux/cmux.
        aaqa.tmux.accentColor = "colour5";
        aaqa.ghostty.accentColor = "#ff5fd7";

        programs.git.settings.credential = {
          "https://github.com".helper = [
            ""
            "!/home/aaqa/.nix-profile/bin/.gh-wrapped auth git-credential"
          ];
          "https://gist.github.com".helper = [
            ""
            "!/home/aaqa/.nix-profile/bin/.gh-wrapped auth git-credential"
          ];
        };
      }
    )
  ];
}
