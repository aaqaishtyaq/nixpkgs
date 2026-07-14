{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.aaqa.gui = {
    enable = lib.mkEnableOption "Install GUI applications for desktop hosts";
  };

  config = {
    # Direnv, load and unload environment variables depending on the current directory.
    # https://direnv.net
    # https://rycee.gitlab.io/home-manager/options.html#opt-programs.direnv.enable
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;

    # Htop
    # https://rycee.gitlab.io/home-manager/options.html#opt-programs.htop.enable
    programs.htop.enable = true;
    programs.htop.settings.show_program_path = true;

    # SSH
    # https://nix-community.github.io/home-manager/options.html#opt-programs.ssh.enable
    # Some options also set in `../darwin/homebrew.nix`.
    programs.ssh.enable = true;
    programs.ssh.enableDefaultConfig = false;
    programs.ssh.settings."*" = {
      ControlPath = "~/.ssh/%C";
    };
    programs.ssh.extraConfig = ''
      Host sirius
          HostName sirius.aaqa.dev
          User aaqaishtyaq
      Host gcp
          HostName gcp.aaqa.dev
          User aaqaishtyaq

    ''
    + lib.optionalString pkgs.stdenv.isDarwin ''
      Include ~/.orbstack/ssh/config
    ''
    + ''
      Include ~/.ssh/local_config
    '';

    programs.zoxide.enable = true;

    targets.genericLinux.enable = !pkgs.stdenv.isDarwin;
    fonts.fontconfig.enable = !pkgs.stdenv.isDarwin;

    programs.fzf = {
      enableZshIntegration = true;
      enable = true;
    };

    home.packages = lib.attrValues (
      {
        # Some basics
        inherit (pkgs)
          bandwhich # display current network utilization by process
          bottom # fancy version of `top` with ASCII graphs
          coreutils
          curl
          dust # fancy version of `du`
          fd # fancy version of `find`
          htop # fancy version of `top`
          ripgrep # better version of `grep`
          tealdeer # rust implementation of `tldr`
          unrar # extract RAR archives
          wget
          xz # extract XZ archives
          iay
          gnupg
          diff-so-fancy
          fzf
          tree
          jq
          yq
          aria2
          zstd
          parallel
          mosh
          gnutar
          universal-ctags
          bat
          git-crypt
          rclone
          restic

          nixd
          nixfmt
          nixfmt-tree

          rustscan
          nmap
          ;

        # Runtimes
        inherit (pkgs)
          go_1_25
          pkg-config
          bundix
          gnumake
          sqlite
          libpcap
          zlib
          rustup
          ;

        # GoLang
        inherit (pkgs)
          gotests
          golangci-lint
          gomodifytags
          impl
          go-tools
          delve
          gopls
          gofumpt
          go-outline
          godef
          golint
          ;

        gcloud = pkgs.google-cloud-sdk.withExtraComponents [
          pkgs.google-cloud-sdk.components.gke-gcloud-auth-plugin
        ];

        # Dev stuff
        inherit (pkgs)
          cloc # source code line counter
          nodejs
          typescript
          kubectl
          awscli2
          kubectx
          # redis
          kubernetes-helm
          k9s
          terraform
          natscli
          pnpm
          gh
          ;

        inherit (pkgs.unixtools)
          watch
          ;

        # Useful nix related tools
        inherit (pkgs)
          cachix # adding/managing alternative binary caches hosted by Cachix
          comma # run software from without installing it
          # niv # easy dependency management for nix projects
          nix-output-monitor # get additional information while building packages
          nix-tree # interactively browse dependency graphs of Nix derivations
          nix-update # swiss-knife for updating nix packages
          nixpkgs-review # review pull-requests on nixpkgs
          statix # lints and suggestions for the Nix programming language
          nil # nix lsp
          ;

        # GUI
        inherit (pkgs)
          weechat
          yt-dlp
          ;

        # python packages
        inherit (pkgs.python312Packages)
          git-filter-repo
          ;

      }
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        inherit (pkgs)
          pinentry_mac
          cocoapods
          m-cli # useful macOS CLI commands
          ;
      }
      // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
        inherit (pkgs)
          pinentry-curses
          ;
      }
      //
        lib.optionalAttrs
          (builtins.elem pkgs.stdenv.hostPlatform.system [
            "x86_64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ])
          {
            inherit (pkgs)
              realvnc-vnc-viewer
              ;
          }
      // lib.optionalAttrs (!pkgs.stdenv.isDarwin && config.aaqa.gui.enable) {
        inherit (pkgs)
          ghostty
          ibm-plex
          vlc
          vscode
          zed-editor
          ;
      }
    );

    home.file = {
      ".local/bin/alatheme".source = ./bin/alatheme;
      ".local/bin/datepath".source = ./bin/datepath;
      ".local/bin/git-checkout-ss".source = ./bin/git-checkout-ss;
      ".local/bin/git-diff-exclude".source = ./bin/git-diff-exclude;
      ".local/bin/git-reset-fetch-head".source = ./bin/git-reset-fetch-head;
      ".local/bin/hnow".source = ./bin/hnow;
      ".local/bin/inc.awk".source = ./bin/inc.awk;
      ".local/bin/logg".source = ./bin/logg;
      ".local/bin/mkdirp".source = ./bin/mkdirp;
      ".local/bin/muxx".source = ./bin/muxx;
      ".local/bin/nixfmt-all".source = ./bin/nixfmt-all;
      ".local/bin/notes".source = ./bin/notes;
      ".local/bin/now".source = ./bin/now;
      ".local/bin/nvim-mode".source = ./bin/nvim-mode;
      ".local/bin/todo".source = ./bin/todo;
      ".local/bin/zzip".source = ./bin/zzip;
      ".gitignore".source = ./bin/gitignore;
    };
  };
}
