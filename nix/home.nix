{ config, pkgs, lib, ... }:

{
  home.username = "aki";
  home.homeDirectory = "/Users/aki";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    zsh-completions
    fzf
    gh
    ghq
    # (lazygit is configured via programs.lazygit below)
    yq-go # mikefarah Go implementation, not the Python yq
    zk
    kubelogin
    neovim
    tmux
    azure-cli
    podman
    podman-compose
    # not bundled by nix podman; the applehv machine finds it via
    # helper_binaries_dir in ~/.config/containers/containers.conf
    vfkit
    # TUI tools
    lazysql
    rainfrog
    # yarn classic; bundles its own node for itself, project builds use
    # whatever node is on PATH (a devShell node, else the global one below)
    yarn
    # Global fallback runtimes for everything outside a project devShell —
    # nvim LSP servers need a node on PATH, and ad-hoc java/mvn/go in
    # random directories should still work.
    nodejs_22
    temurin-bin # jdk 21 LTS
    maven
    go
  ];

  programs.home-manager.enable = true;

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };

  # Per-project toolchains: a work repo opts in with a gitignored one-line
  # .envrc (`use flake <this repo>#bff`) and the devShell swaps in on cd.
  # nix-direnv caches the evaluated env, so re-entering is instant.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.zsh = {
    enable = true;
    # NOTE: plugins load synchronously
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      emacs = "nvim";
      code = "nvim";
      # Claude Code launcher; intentionally shadows /usr/bin/cc at the prompt.
      # Build tools ignore shell aliases and still get the real compiler.
      cc = "cd ~/cc && claude";
    };

    sessionVariables = {
      EDITOR = "nvim";
      ZK_NOTEBOOK_DIR = "${config.home.homeDirectory}/dev/src/github.com/akihiko-minamisawa/notes";
      GOOGLE_CLOUD_PROJECT = "backend-credentials";
    };

    # Homebrew PATH/env setup (login shells)
    profileExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';

    # Ordered after home-manager's own compinit / plugin / integration blocks.
    initContent = lib.mkOrder 1000 ''
        ### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
        export PATH="/Users/aki/.rd/bin:$PATH"
        ### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

        # nix CLI bootstrap. macOS updates rewrite /etc/zshrc and can drop the
        # installer's block there, so own it here; the script's own guard makes
        # it a no-op when the /etc copy is intact. Sourced before the prepend
        # below so the user profile still ends up first.
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi

        # Nix profiles first — macOS path_helper reorders system dirs to the
        # front, letting /usr/bin or brew copies shadow declared packages.
        # Lives in .zshrc (not home.sessionPath/.zshenv) because the sessionPath
        # guard skips shells inheriting an initialized env, e.g. tmux panes.
        # Order: user profile > nix-darwin system profile.
        export PATH="$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"

        # Azure cli setting (completion ships with the nix azure-cli package)
        autoload bashcompinit && bashcompinit
        source ~/.nix-profile/share/bash-completion/completions/az.bash

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

        # Work-specific helpers live outside version control (this repo is
        # public); absent on a fresh machine, so the guard is load-bearing.
        if [[ -f "$HOME/dev/src/github.com/akihiko-minamisawa/dotfiles/home/.zshrc.local" ]]; then
          source "$HOME/dev/src/github.com/akihiko-minamisawa/dotfiles/home/.zshrc.local"
        fi
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
      "# mise (retired; ignores kept so stale local files stay invisible)"
      ".mise.local.toml"
      ".mise.*.local.toml"
      ""
      "# direnv (per-project devShells; .envrc is machine-local by design)"
      ".envrc"
      ".direnv/"
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

      # histogram beats myers on reformat-heavy Java diffs; colorMoved paints
      # pure code moves so a relocation stops reading as add + delete.
      diff = {
        algorithm = "histogram";
        colorMoved = "default";
        colorMovedWS = "allow-indentation-change";
        mnemonicPrefix = true;
        renames = "copies";
      };

      # side-by-side off globally: lazygit's diff pane is too narrow for it
      # (delta reads these same keys there). `git ds` opts in per use.
      alias.ds = "-c delta.side-by-side=true diff";
    };
  };

  # delta: enableGitIntegration wires every git pager and interactive.diffFilter
  # from one declaration (set explicitly — the module deprecated inferring it).
  # gh is NOT covered: `gh pr diff N | delta` for PRs.
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      # n/N jumps file to file. Not repeated in the lazygit pager below —
      # upstream documents --navigate as non-functional there.
      navigate = true;
      line-numbers = true;
      hyperlinks = true;
      side-by-side = false;
      syntax-theme = "Nord";
    };
  };

  # hunk (hunk.dev): terminal diff viewer, from its upstream flake (flake.nix).
  # Integrations stay off: git integration would steal core.pager from delta,
  # and the Claude one collides with the out-of-store ~/.claude symlink below.
  programs.hunk.enable = true;

  programs.lazygit = {
    enable = true;
    settings.git.pagers = [
      {
        # --paging=never: lazygit scrolls itself. lazygit-edit:// hyperlinks
        # make diff-pane paths clickable, opening nvim at that line.
        pager = ''delta --dark --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format="lazygit-edit://{path}:{line}"'';
      }
    ];
  };

  # ~/.claude: live Claude Code state (settings/skills tracked; agents/memory
  # gitignored). Out-of-store symlink — Claude Code writes here constantly,
  # so it must never resolve into the read-only nix store.
  home.file.".claude" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dev/src/github.com/akihiko-minamisawa/dotfiles/home/.claude";
    # a live Claude Code process recreates ~/.claude within seconds, so
    # activation may find a foreign dir here — overwrite, don't abort
    force = true;
  };

  xdg.configFile = let
    # Live-editable configs: ~/.config/<name> symlinks straight into the repo,
    # OUT of the store. nvim requires this (lazy.nvim writes lazy-lock.json
    # into its config dir); the rest are tweaked in place often enough that
    # edit-without-switch beats store purity.
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
