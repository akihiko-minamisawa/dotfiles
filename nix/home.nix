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
    # lazygit moved to programs.lazygit below — it needs a config.yml (delta as
    # its pager), and the module knows darwin puts that under
    # ~/Library/Application Support rather than ~/.config.
    sl
    tree
    yq-go # brew yq (mikefarah Go implementation), not the Python yq
    zk
    # was brew azure/kubelogin/kubelogin; moved off brew when tap trust
    # enforcement broke `brew bundle`
    kubelogin
    # editors/multiplexer, migrated together with their configs (which live
    # as out-of-store symlinks under xdg.configFile below)
    neovim
    tmux
    # wave 2: same-version swap from brew (2.85.0); az login state and
    # extensions live in ~/.azure, unaffected by the binary swap
    azure-cli
    gemini-cli
    # wave 3: container/VM tooling and standalone dev CLIs off brew
    flyway
    podman
    podman-compose
    qemu
    # NOT bundled by nix podman (its libexec ships only gvproxy/gvforwarder/
    # qemu-wrapper), but the existing podman machine is applehv and needs
    # vfkit to start. Found via helper_binaries_dir in
    # ~/.config/containers/containers.conf — that file is live podman state,
    # deliberately not home-manager managed.
    vfkit
    # TUI tools
    lazysql
    rainfrog
    yazi
    # yarn classic; bundles its own node for running itself. Project builds
    # use whatever node is on PATH (a devShell node, else the global one
    # below). Dropping brew yarn also drops brew node, which existed only as
    # yarn's dependency.
    yarn
    # Global fallback runtimes, mirroring the retired mise global config
    # (node 22 / java 21 / maven / go). Per-project versions come from the
    # devShells in flake.nix via direnv; these cover everything outside a
    # project shell — nvim LSP servers and plugins need a node on PATH, and
    # ad-hoc `java`/`mvn`/`go` in random directories should still work.
    nodejs_22
    temurin-bin # jdk 21 LTS
    maven
    go
  ];

  programs.home-manager.enable = true;

  programs.starship = {
    enable = true;
    # home-manager owns `starship init zsh` now that sheldon is gone.
    enableZshIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };

  # direnv + nix-direnv: per-project toolchains via the devShells in flake.nix
  # (replaced mise). A work repo opts in with a gitignored one-line .envrc —
  # `use flake ~/dev/src/github.com/akihiko-minamisawa/dotfiles#bff` — and the
  # runtime set swaps on cd, like mise did. nix-direnv caches the evaluated
  # env under the repo's .direnv/, so re-entering a directory is instant.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
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
      # Intentionally shadows /usr/bin/cc (the C compiler) at the interactive
      # prompt; build tools (make/cmake/node-gyp) ignore shell aliases and still
      # resolve the real /usr/bin/cc via PATH, so direct compilation is unaffected.
      cc = "cd ~/cc && claude";
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

        # nix CLI bootstrap (/nix/var/nix/profiles/default/bin + NIX_SSL_CERT_FILE
        # etc). The official installer put this in /etc/zshrc, but macOS updates
        # rewrite that file and silently drop the block (bit us 2026-06-25:
        # `nix` vanished from zsh PATH). Owning it here survives OS updates;
        # the script's __ETC_PROFILE_NIX_SOURCED guard makes it a no-op when
        # the /etc/zshrc copy is intact. Sourced before the prepend below so
        # the user profile still ends up first.
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi

        # Nix profiles first: macOS path_helper (/etc/zprofile) reorders system
        # dirs to the front, leaving ~/.nix-profile/bin dead last — so any
        # /usr/bin or brew copy shadowed the declared nix package (e.g. system
        # jq 1.7.1 over nix jq 1.8.1). Prepending here makes declared packages
        # win. Safety verified before enabling: nix man renders system man
        # pages fine, nix git == brew git 2.53.0.
        # Kept in .zshrc rather than home.sessionPath: sessionPath lands in
        # ~/.zshenv behind the __HM_SESS_VARS_SOURCED guard, which is skipped
        # by shells inheriting an initialized env (e.g. panes of a long-running
        # tmux server). .zshrc runs unconditionally per interactive shell.
        # Order: user profile > nix-darwin system profile (darwin-rebuild etc).
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

      # Diff quality knobs that need no extra tooling. histogram beats the
      # default myers on the reformat-heavy Java diffs in the BFF repos, and
      # colorMoved paints pure code moves in a separate color so "this block
      # just relocated" stops reading as an add plus a delete during review.
      diff = {
        algorithm = "histogram";
        colorMoved = "default";
        colorMovedWS = "allow-indentation-change";
        mnemonicPrefix = true;
        renames = "copies";
      };

      # side-by-side is off globally because lazygit's diff pane is too narrow
      # for it (delta reads these same [delta] keys when lazygit invokes it).
      # `git ds` opts in for the occasional full-width read.
      alias.ds = "-c delta.side-by-side=true diff";
    };
  };

  # delta: the pager layer. enableGitIntegration points the blame/diff/log/show
  # pagers and interactive.diffFilter at delta, so plain diffs and `git add -p`
  # both render through it from one declaration. Set explicitly because the
  # module deprecated inferring it. Note gh has its own pager and is NOT
  # covered by this — `gh pr diff N | delta` for PRs.
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      # n/N jumps file to file in the CLI pager. Deliberately not repeated in
      # the lazygit pager string below — upstream documents --navigate as
      # non-functional there, so it would be dead config.
      navigate = true;
      line-numbers = true;
      hyperlinks = true;
      side-by-side = false;
      syntax-theme = "Nord";
    };
  };

  # hunk (hunk.dev): review-first terminal diff viewer for agent-authored
  # changesets. Module + package come from the upstream flake (wired in
  # flake.nix). Integration toggles stay off: enableGitIntegration would
  # steal git core.pager from delta above, and enableClaudeIntegration
  # writes into ~/.claude, which is an out-of-store symlink here (below) —
  # home-manager would collide trying to nest store files inside it.
  programs.hunk.enable = true;

  programs.lazygit = {
    enable = true;
    settings.git.pagers = [
      {
        # --paging=never because lazygit does its own scrolling. The
        # lazygit-edit:// link format turns file paths in the diff pane into
        # clickable targets that open nvim at that line, which is the whole
        # reason for wiring hyperlinks through here.
        pager = ''delta --dark --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format="lazygit-edit://{path}:{line}"'';
      }
    ];
  };

  # ~/.claude: live Claude Code state (settings/skills tracked in the repo;
  # agents/memory gitignored). Out-of-store symlink into the repo — the same
  # link install.sh used to create. Claude Code writes here constantly, so it
  # must never resolve into the read-only nix store.
  home.file.".claude" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dev/src/github.com/akihiko-minamisawa/dotfiles/home/.claude";
    # A live Claude Code process recreates ~/.claude within seconds of it
    # disappearing, so activation may find a foreign dir/link here; overwrite
    # it instead of aborting the whole switch (the real state lives in the
    # repo, the recreated one is seconds-old scratch).
    force = true;
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
