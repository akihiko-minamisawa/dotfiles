{ config, pkgs, lib, ... }:

{
  home.username = "aki";
  home.homeDirectory = "/Users/aki";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    # Extra completion definitions; land in the nix profile's
    # share/zsh/site-functions, which home-manager already puts on fpath.
    zsh-completions
    # Standalone CLIs migrated off Homebrew (wave 1). Plain packages, no
    # programs.* modules, to keep exact behavior parity with the brew installs.
    fzf
    gh
    ghq
    git-filter-repo
    go-migrate # brew golang-migrate; installs the `migrate` binary
    lazygit
    sl
    tree
    yq-go # brew yq (mikefarah Go implementation), not the Python yq
    zk
    # was brew azure/kubelogin/kubelogin; moved off brew when tap trust
    # enforcement broke `brew bundle` (see darwin.nix)
    kubelogin
    # editors/multiplexer, migrated together with their configs (which live
    # as out-of-store symlinks under xdg.configFile below)
    neovim
    tmux
  ];

  programs.home-manager.enable = true;

  programs.starship = {
    enable = true;
    # home-manager owns `starship init zsh` now that sheldon is gone.
    enableZshIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };

  # mise activation, previously run via sheldon (`eval "$(mise activate zsh)"`).
  # Moves mise off Homebrew onto nixpkgs; installed tool versions live in
  # ~/.local/share/mise and are independent of which mise binary reads them.
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    # home-manager now owns what sheldon used to: compinit + zsh plugins.
    # NOTE: these load synchronously (sheldon used zsh-defer for async load).
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

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

    # Ordered after home-manager's own compinit / plugin / integration blocks.
    initContent = lib.mkOrder 1000 ''
        ### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
        export PATH="/Users/aki/.rd/bin:$PATH"
        ### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

        # nix-darwin system profile (darwin-rebuild + any system packages).
        # Kept here in .zshrc rather than home.sessionPath: sessionPath lands in
        # ~/.zshenv behind the __HM_SESS_VARS_SOURCED guard, which is skipped by
        # shells that inherit an already-initialized env (e.g. panes from a
        # long-running tmux server). .zshrc runs unconditionally per interactive
        # shell, so darwin-rebuild is always on PATH.
        export PATH="/run/current-system/sw/bin:$PATH"

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
    '';
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

  xdg.configFile = let
    # Live-editable configs, declared here but kept OUT of the nix store:
    # ~/.config/<name> symlinks straight into the repo checkout (the same
    # layout install.sh used to create). nvim requires this — lazy.nvim
    # writes lazy-lock.json into the config dir, and a store path would be
    # read-only. The rest are tweaked in place often enough that
    # edit-without-switch is worth more than store purity.
    live = path: config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dev/src/github.com/akihiko-minamisawa/dotfiles/home/.config/${path}";
  in {
    # git hooks are not covered by the programs.git module; link them in directly.
    "git/hooks".source = ./git/hooks;

    "ghostty".source = live "ghostty";
    "nix".source = live "nix";
    "nvim".source = live "nvim";
    "tmux".source = live "tmux";
    "wezterm".source = live "wezterm";
    "zk".source = live "zk";
  };
}
