{ config, pkgs, ... }:

{
  home.username = "aki";
  home.homeDirectory = "/Users/aki";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
  ];

  programs.home-manager.enable = true;

  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };

  programs.git = {
    enable = true;

    attributes = [
      "third-party-report.html merge=union"
    ];

    ignores = [
      "# Mac"
      ".DS_Store"
      ""
      "# IntelliJ"
      ".idea/"
      ""
      "# VSCode"
      ".vscode/*"
      "!.vscode/settings.json"
      "!.vscode/tasks.json"
      "!.vscode/launch.json"
      "!.vscode/extensions.json"
      ""
      "# mise"
      ".mise.local.toml"
      ".mise.*.local.toml"
      ""
      "# Claude Code"
      "**/.claude/settings.local.json"
    ];

    settings = {
      user = {
        name = "Akihiko Minamisawa";
        email = "akihiko-minamisawa@mail.nissan.co.jp";
      };
      pull = {
        ff = "only";
        rebase = false;
      };
      push.autoSetupRemote = true;
      core.hooksPath = "${config.xdg.configHome}/git/hooks";
      submodule.recurse = true;
      init.defaultBranch = "main";
      commit.template = "~/.stCommitMsg";
      ghq.root = "~/dev/src";
    };
  };

  # git hooks are not covered by the programs.git module; link them in directly.
  xdg.configFile."git/hooks".source = ./git/hooks;
}
