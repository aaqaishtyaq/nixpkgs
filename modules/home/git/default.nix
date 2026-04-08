{
  config,
  lib,
  ...
}:

let
  cfg = config.home.user-info;
in
{
  config = {
    programs.git = {
      enable = true;
      signing = {
        key = "AFB766F59A198D35DD8F925AC4BE1CE588EB9E21";
      };
      settings = {
        alias = {
          st = "status -s";
          lol = "log --oneline --graph --all";
        };
        branch.sort = "-committerdate";
        column.ui = "auto";
        core = {
          excludesFile = "~/.gitignore";
          pager = "diff-so-fancy | less --tabs=4 -RFX";
        };
        diff.algorithm = "histogram";
        http.cookiefile = "${config.home.homeDirectory}/.gitcookies";
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        tag.sort = "version:refname";
        user = {
          email = cfg.email;
          name = cfg.fullName;
        };
      };
    };
  };
}
