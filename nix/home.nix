{ config, pkgs, lib, ... }:

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
    # sheldon already runs `starship init zsh` (plugins.toml); don't double-inject.
    enableZshIntegration = false;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };

  programs.zsh = {
    enable = true;
    # sheldon (plugins.toml) owns compinit / mise / starship / plugins; let it.
    enableCompletion = false;

    shellAliases = {
      emacs = "nvim";
      code = "nvim";
      # Claude Code workspace launchers (~/cc = general AI assistant workspace).
      # `cl` chosen over `cc` to avoid shadowing /usr/bin/cc (the C compiler).
      cl = "cd ~/cc && claude";
    };

    sessionVariables = {
      EDITOR = "nvim";
      ZK_NOTEBOOK_DIR = "${config.home.homeDirectory}/dev/src/github.com/akihiko-minamisawa/notes";
      GOOGLE_CLOUD_PROJECT = "backend-credentials";
    };

    # Homebrew PATH/env setup (login shells). Previously an untracked ~/.zprofile.
    profileExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';

    initContent = lib.mkMerge [
      # Load plugins first, like the original .zshrc.
      (lib.mkOrder 500 ''
        eval "$(sheldon source)"
      '')
      (lib.mkOrder 1000 ''
        ### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
        export PATH="/Users/aki/.rd/bin:$PATH"
        ### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

        # Azure cli setting
        autoload bashcompinit && bashcompinit
        source $(brew --prefix)/etc/bash_completion.d/az

        export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
        export PATH="$HOME/.local/bin:$PATH"

        # Added by Antigravity
        export PATH="/Users/aki/.antigravity/antigravity/bin:$PATH"

        # Select and cd to a ghq-managed repository using fzf
        function gf() {
          local dir
          dir=$(ghq list -p | fzf --preview "ls -la {}")
          if [[ -n "$dir" ]]; then
            cd "$dir"
          fi
        }

        # Select and cd to a directory using fzf (-a to include hidden directories)
        function cf() {
          local dir
          local fd_opts="--type d"
          if [[ "$1" == "-a" || "$1" == "--all" ]]; then
            fd_opts="$fd_opts --hidden"
          fi
          dir=$(fd ''${=fd_opts} | fzf)
          if [[ -n "$dir" ]]; then
            cd "$dir"
          fi
        }

        # Select a file using fzf and open it in nvim (-a to include hidden files)
        function of() {
          local file
          local fd_opts="--type f"
          if [[ "$1" == "-a" || "$1" == "--all" ]]; then
            fd_opts="$fd_opts --hidden"
          fi
          file=$(fd ''${=fd_opts} | fzf --preview "bat --color=always {} 2>/dev/null || cat {}")
          if [[ -n "$file" ]]; then
            nvim "$file"
          fi
        }
      '')
    ];
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
