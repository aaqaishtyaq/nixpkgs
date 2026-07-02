{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.aaqa.zsh;
  dotDir = "${config.home.homeDirectory}/.config/zsh.d";
in
{
  options.aaqa.zsh = {
    enable = mkEnableOption "Enable the Z Shell";
    extraSessionVariables = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Extra session variables to merge into zsh sessionVariables.";
    };
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
        path = "${dotDir}/.zsh_history";
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
        tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
        chmox = "chmod u+x";
        cl = "clear";
        ctags = if pkgs.stdenv.isDarwin then "/usr/local/bin/ctags" else "ctags";
        e = "nvim";
        ga = "git add";
        gb = "git branch";
        gbl = "git blame -b -w";
        gc = "git commit -m";
        gd = "git diff";
        gds = "git diff --staged";
        gfo = "git fetch origin";
        gl = "git pull";
        glod = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'";
        glods = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset' --date=short";
        glog = "git log --all --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        glol = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'";
        glola = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --all";
        glols = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --stat";
        grep = "grep --color=auto";
        gp = "git push";
        gpu = "git push upstream";
        gr = "git remote";
        gra = "git remote add";
        grehfh = "git reset --hard FETCH_HEAD";
        grehh = "git reset --hard HEAD";
        grv = "git remote -v";
        gs = "git status";
        gst = "git status -s";
        gsh = "git show";
        gsi = "git submodule init";
        ipaddr = "dig +short myip.opendns.com @resolver1.opendns.com";
        ipinfo = "curl ipinfo.io";
        more = "less -R";
        weather = "curl wttr.in";
        nixclean = "nix-collect-garbage -d";
        nfmt = "nixfmt-all";
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
        LC_MESSAGES = "en_US";
        GOPATH = "$HOME/Developer/go";
        NVM_DIR = "$HOME/.nvm";
        PNPM_HOME = "$HOME/.local/share/pnpm";
        KNPATH = "$HOME/Developer/go/src/github.com/aaqa/jottings";
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_CONFIG_HOME = "$HOME/.config";
        XDG_CACHE_HOME = "$HOME/.cache";
      }
      // cfg.extraSessionVariables;
      initContent = ''
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
      ''
      + optionalString pkgs.stdenv.isDarwin ''
        _brew_env_cache="''${XDG_CACHE_HOME:-$HOME/.cache}/brew_shellenv"
        if [[ ! -f "$_brew_env_cache" || /opt/homebrew/bin/brew -nt "$_brew_env_cache" ]]; then
          mkdir -p "''${XDG_CACHE_HOME:-$HOME/.cache}"
          /opt/homebrew/bin/brew shellenv >| "$_brew_env_cache"
        fi
        source "$_brew_env_cache"
        unset _brew_env_cache
      ''
      + ''
        ZSH_AUTOSUGGEST_USE_ASYNC=true

        export GPG_TTY=$(tty)
        path=("$GOPATH/bin" $path)
        export PATH

        for file in "${dotDir}/"*.zsh; do
          if [[ -r "$file" ]] && [[ -f "$file" ]]; then
            source "$file"
          fi
        done

        if [ ! "$TERM" = dumb ]; then
          autoload -Uz add-zsh-hook
          _iay_prompt() {
            PROMPT="$(iay -zm)"
          }
          add-zsh-hook precmd _iay_prompt
        fi

        RPROMPT=""
      ''
      + optionalString pkgs.stdenv.isDarwin ''
        export PLAN9=/usr/local/plan9
        export PATH=$PATH:$PLAN9/bin
        PATH=$PATH:~/Library/Python/3.9/bin
        export PATH="/opt/homebrew/opt/jpeg/bin:$PATH"
        export LDFLAGS="-L/opt/homebrew/opt/jpeg/lib"
        export CPPFLAGS="-I/opt/homebrew/opt/jpeg/include"
        export PKG_CONFIG_PATH="/opt/homebrew/opt/jpeg/lib/pkgconfig"
        export HOMEBREW_CASK_OPTS="--appdir=~/Applications --fontdir=~/Library/Fonts"
      ''
      + ''
        # lazy-load nvm: defers the slow nvm.sh source until nvm/node/npm/npx is first used
        _nvm_load() {
          unfunction nvm node npm npx 2>/dev/null
          [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
          [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        }
        nvm()  { _nvm_load; nvm  "$@" }
        node() { _nvm_load; node "$@" }
        npm()  { _nvm_load; npm  "$@" }
        npx()  { _nvm_load; npx  "$@" }

        [[ -s "$HOME/.avn/bin/avn.sh" ]] && source "$HOME/.avn/bin/avn.sh"
      '';
    };

    home.sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/Developer/go/bin"
      "${config.home.homeDirectory}/.local/share/pnpm"
      "${config.home.homeDirectory}/.local/share/pnpm/bin"
      "${config.home.homeDirectory}/.antigravity/antigravity/bin"
    ];

    home.file = {
      ".config/zsh.d/aliases.zsh".source = ./aliases.zsh;
      ".config/zsh.d/bindings.zsh".source = ./bindings.zsh;
      ".config/zsh.d/completion.zsh".source = ./completion.zsh;
      ".config/zsh.d/functions.zsh".source = ./functions.zsh;
      ".config/zsh.d/options.zsh".source = ./options.zsh;
    };
  };
}
