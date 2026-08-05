{ ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Nix itself is managed externally (official daemon). Keep nix-darwin off
  # /etc/nix/nix.conf so the manual `ssl-cert-file` fix (required for
  # substitution on this machine) survives.
  nix.enable = false;

  # home-manager owns the user shell; nix-darwin's /etc/zshrc would run a
  # second compinit against it. Disabling also leaves the Nix installer's
  # /etc/zshrc block untouched.
  programs.zsh.enable = false;
  programs.bash.enable = false;

  system.primaryUser = "aki";
  system.stateVersion = 7;

  # Declarative Homebrew: darwin-rebuild switch drives `brew bundle` over this
  # inventory. Casks and Mac App Store apps stay on brew/mas; the brews below
  # stay deliberately — build-time libraries local builds link against, and
  # `brew services`. Standalone CLIs go to home.packages instead and must NOT
  # be listed here; pinned per-project tools go to the devShells in flake.nix.
  homebrew = {
    enable = true;

    onActivation = {
      # If a switch fails with `undefined method '...' for Cask`, the pinned
      # brew is too old for the live cask DSL: `brew update`, then retry.
      autoUpdate = false;
      upgrade = false;
      # Uninstall anything not declared here. Not "zap" — that would also
      # purge cask app data.
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
      # rabbitmq dependency; a nix copy would only shadow-duplicate it
      "erlang"
      # the zshrc PATH entry points here (no client-only nixpkgs package)
      "mysql-client"
      # geo-stack dependency; a nix copy would only shadow-duplicate it
      # (keyring data in ~/.gnupg is binary-independent)
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
      "RunCat Neo" = 6757801838;
      "Xcode" = 497799835;
    };
  };
}
