{ ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";

  # The Nix installation itself is managed externally (official multi-user
  # daemon). Keep nix-darwin from rewriting /etc/nix/nix.conf so the manual
  # `ssl-cert-file = /etc/ssl/cert.pem` (required for substitution to work on
  # this machine) is preserved.
  nix.enable = false;

  # home-manager owns the user shell (compinit, plugins, prompt). Keep
  # nix-darwin from managing /etc/zshrc + /etc/bashrc: its generated /etc/zshrc
  # runs a second `compinit` + `prompt suse`, which would double-initialize
  # against the home-manager setup. Disabling also leaves the official Nix
  # installer's /etc/zshrc block (nix-daemon PATH bootstrap) untouched.
  programs.zsh.enable = false;
  programs.bash.enable = false;

  system.primaryUser = "aki";
  system.stateVersion = 7;

  # Declarative Homebrew: darwin-rebuild switch drives `brew bundle` over this
  # inventory, replacing the hand-maintained home/Brewfile. Casks and Mac App
  # Store apps stay on brew/mas (no nixpkgs equivalent on macOS); the brews
  # below are kept on brew deliberately — build-time libraries (gdal/postgis
  # stack) that local pip/cmake builds link against, and services under
  # `brew services` (postgresql/redis/rabbitmq). Standalone CLIs are migrated
  # to home.packages instead and must NOT be listed here (wave 3, 2026-08-04,
  # moved the container/VM tooling and flyway there; tfenv retired in favor of
  # a pinned terraform devShell in flake.nix, same pattern that replaced mise).
  homebrew = {
    enable = true;

    onActivation = {
      # Known failure mode of autoUpdate = false: cask definitions come from
      # the live API and eventually use DSL the pinned brew doesn't know —
      # a switch then fails with `undefined method '...' for Cask`. Cure:
      # run `brew update` manually and switch again (hit 2026-08-05,
      # `command_wrapper` in drawio needed brew 6.0.11 -> 6.0.15).
      autoUpdate = false;
      upgrade = false;
      # Uninstall anything not declared here (dry-run verified 2026-07-03:
      # inventory matches reality, nothing would be removed today). Not "zap"
      # — that would also purge cask app data via zap stanzas.
      cleanup = "uninstall";
    };

    brews = [
      # gdal/postgis geo stack + the libraries local builds link against
      "apache-arrow"
      "boost"
      "cgal"
      "gdal"
      "glib"
      "gnutls"
      "grpc"
      "harfbuzz"
      "hdf5"
      "jpeg-xl"
      "libheif"
      "llvm"
      "netcdf"
      "numpy"
      "pkgconf"
      "poppler"
      "postgis"
      "sfcgal"
      "sqlite"
      "unbound"
      # services (brew services)
      { name = "postgresql@14"; restart_service = "changed"; }
      "rabbitmq"
      "redis"
      # kept on brew: pure dependency of the rabbitmq service above — a nix
      # copy would only shadow-duplicate it (same reasoning as gnupg below).
      "erlang"
      # (dropped in wave 3, 2026-08-04: docker-buildx/docker-compose deleted
      # outright — Rancher Desktop's ~/.rd/bin copies were the ones actually
      # resolving, both on PATH and via the ~/.docker/cli-plugins symlinks, so
      # the brew pair was dead weight. podman/podman-compose/qemu/flyway moved
      # to home.packages; openjdk left with flyway, its only consumer. tfenv
      # replaced by the pinned terraform devShell in flake.nix.
      # Historical: sdkman dropped 2026-07-03 when untrusted-tap refusal broke
      # brew bundle; kubelogin moved to nixpkgs then for the same reason.)
      # kept on brew deliberately: the zshrc PATH entry points at
      # /opt/homebrew/opt/mysql-client (no clean client-only nixpkgs package)
      "mysql-client"
      # kept on brew: hard dependency of the geo stack (gdal/poppler/postgis
      # refuse to let it go), so a nix copy would only shadow-duplicate it.
      # Keyring data (~/.gnupg) is binary-independent anyway.
      "gnupg"
      # required by masApps below
      "mas"
    ];

    casks = [
      "antigravity"
      "battery"
      "bruno"
      "claude"
      "claude-code"
      "cursor"
      "deepl"
      "devtoys"
      "drawio"
      "firefox"
      "font-plemol-jp-nf"
      "gcloud-cli"
      "ghostty"
      "github-copilot-for-xcode"
      "intellij-idea"
      "intune-company-portal"
      "microsoft-auto-update"
      "obsidian"
      "openvpn-connect"
      "pgadmin4"
      "postman"
      "pritunl"
      # both had been ad-hoc installs and were swept by the wave 3 cleanup;
      # redeclared 2026-08-05 (Raycast's settings survived the sweep).
      "raspberry-pi-imager"
      "raycast"
      "sublime-text"
      "visual-studio-code"
      "visual-studio-code@insiders"
      "wezterm@nightly"
    ];

    masApps = {
      "Azure VPN Client" = 1553936137;
      "GarageBand" = 682658836;
      "iMovie" = 408981434;
      "Keynote" = 409183694;
      "Kindle" = 302584613;
      "LINE" = 539883307;
      "Microsoft Excel" = 462058435;
      "Microsoft OneNote" = 784801555;
      "Microsoft Outlook" = 985367838;
      "Microsoft PowerPoint" = 462062816;
      "Microsoft Word" = 462054704;
      "Numbers" = 409203825;
      "OneDrive" = 823766827;
      "Pages" = 409201541;
      # RunCat's original listing (1429033973) was pulled from the App Store;
      # RunCat Neo is its successor app under a new ADAM ID (2026-08-05).
      "RunCat Neo" = 6757801838;
      "Xcode" = 497799835;
    };
  };
}
