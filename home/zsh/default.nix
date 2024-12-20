{config, lib, pkgs, ...}:

with lib;

let
  cfg = config.aaqaishtyaq.zsh;
  dotDir = ".config/zsh.d";
in {
  options.aaqaishtyaq.zsh = {
    enable = mkEnableOption "Enable the Z Shell";
  };
  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      dotDir = "${dotDir}";
      enableCompletion = true;
      autosuggestion = {
        enable = true;
      };
      history = {
        path = "$HOME/${dotDir}/.zsh_history";
        save = 50000;
        ignoreDups = true;
        share = true;
        extended = true;
      };
      autocd = true;
      shellAliases = {
        k = "kubectl";
        kctx = "kubectx";
        kns = "kubens";
        kx = "kubectx";
        ls = "ls --color=auto";
        l = "ls -lah";
        la = "ls -lAh";
        ll = "ls -lh";
        lsa = "ls -lah";
        sl = "ls -al";
        tree = "tree -C";
        chmox = "chmod u+x";
        cl = "clear";
        ctags = "/usr/local/bin/ctags";
        e = "nvim";
        grep = "grep --color=auto";
        ipaddr = "dig +short myip.opendns.com @resolver1.opendns.com";
        ipinfo = "curl ipinfo.io";
        more = "less -R";
        weather = "curl wttr.in";
        nixclean = "nix-collect-garbage -d";
        mnt-drive = "udisksctl mount -b /dev/sda1";
      };
      sessionVariables = {
        EDITOR = "vim";
        HISTCONTROL = "ignoreboth";
        PAGER = "less";
        LESS = "-iR";
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
        LC_CTYPE = "en_US";
        LC_MESSAGES="en_US";
      };
      initExtra = ''
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi

        eval "$(/opt/homebrew/bin/brew shellenv)"

        eval "$(direnv hook zsh)"
        ZSH_AUTOSUGGEST_USE_ASYNC=true

        export GPG_TTY=$(tty)

        for file in "$HOME/${dotDir}/"*.zsh; do
          if [[ -r "$file" ]] && [[ -f "$file" ]]; then
            source "$file"
          fi
        done

        if command -v grep &>/dev/null; then
          if [ -r ~/.config/dircolors/dircolors ]; then
            eval "$(dircolors -b ~/.config/dircolors/dircolors)"
          else
            eval "$(dircolors -b)"
          fi
        fi

        if [ ! "$TERM" = dumb ]; then
          autoload -Uz add-zsh-hook
          _iay_prompt() {
            PROMPT="$(iay -zm)"
          }
          add-zsh-hook precmd _iay_prompt
        fi

        RPROMPT=""

        export PLAN9=/usr/local/plan9
        export PATH=$PATH:$PLAN9/bin
        PATH=$PATH:~/Library/Python/3.9/bin

        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
        [[ -s "$HOME/.avn/bin/avn.sh" ]] && source "$HOME/.avn/bin/avn.sh" # load avn

        export KNPATH="$HOME/Developer/go/src/github.com/aaqa/jottings"
        export PATH="$HOME/.local/bin":$PATH
        export GOPATH="$HOME/Developer/go"

        # jpeg is keg-only, which means it was not symlinked into /opt/homebrew,
        # because it conflicts with `jpeg-turbo`.
        export PATH="/opt/homebrew/opt/jpeg/bin:$PATH"
        # For compilers to find jpeg need to set:
        export LDFLAGS="-L/opt/homebrew/opt/jpeg/lib"
        export CPPFLAGS="-I/opt/homebrew/opt/jpeg/include"
        # For pkg-config to find jpeg need to set:
        export PKG_CONFIG_PATH="/opt/homebrew/opt/jpeg/lib/pkgconfig"

        export HOMEBREW_CASK_OPTS="--appdir=~/Applications --fontdir=~/Library/Fonts"
      '';
    };

    home.file = {
      ".config/zsh.d/aliases.zsh".source = ./aliases.zsh;
      ".config/zsh.d/bindings.zsh".source = ./bindings.zsh;
      ".config/zsh.d/completion.zsh".source = ./completion.zsh;
      ".config/zsh.d/functions.zsh".source = ./functions.zsh;
      ".config/zsh.d/options.zsh".source = ./options.zsh;
      ".config/dircolors/dircolors".source = ../dircolors/dircolors;
    };
  };
}
