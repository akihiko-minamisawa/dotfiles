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
  # stack) that local pip/cmake builds link against, services under
  # `brew services` (postgresql/redis/rabbitmq), container tooling tied to
  # Rancher Desktop, and version managers that self-manage installs
  # (tfenv/sdkman). Standalone CLIs are migrated to home.packages instead and
  # must NOT be listed here.
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      # "none" while the inventory settles; raise to "uninstall"/"zap" later
      # so undeclared packages get removed on switch.
      cleanup = "none";
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
      # container / VM tooling (Rancher Desktop integration)
      "docker-buildx"
      "docker-compose"
      "podman"
      "podman-compose"
      "qemu"
      # language runtimes / dev platforms
      "erlang"
      "flyway"
      "openjdk"
      # version managers that manage their own installs
      # (sdkman dropped 2026-07-03: untrusted-tap refusal broke brew bundle;
      # Java is covered by the declared openjdk + mise. kubelogin moved to
      # nixpkgs for the same reason. Both taps removed with them.)
      "tfenv"
      # CLIs pending migration to nixpkgs (wave 2: shell-integration edits needed)
      "azure-cli"
      "gemini-cli"
      "gnupg"
      "mysql-client"
      "yarn"
      # CLIs migrating together with their configs (home-manager modules)
      "neovim"
      "tmux"
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
      "RunCat" = 1429033973;
      "Xcode" = 497799835;
    };
  };
}
