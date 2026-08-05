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
      # the zshrc PATH entry points here (no client-only nixpkgs package)
      "mysql-client"
      # geo-stack dependency; a nix copy would only shadow-duplicate it
      # (keyring data in ~/.gnupg is binary-independent)
      "gnupg"
      # required by masApps below
      "mas"
    ];

    casks = [
      "battery"
      "bruno"
      "claude"
      "claude-code"
      "deepl"
      "firefox"
      "font-plemol-jp-nf"
      "gcloud-cli"
      "ghostty"
      "google-chrome"
      "google-drive"
      "intune-company-portal"
      "microsoft-auto-update"
      "notion"
      "ollama-app"
      "raspberry-pi-imager"
      "raycast"
      "slack"
      "wezterm@nightly"
    ];

    masApps = {
      "Azure VPN Client" = 1553936137;
      "Kindle" = 302584613;
      "LINE" = 539883307;
      "Microsoft Excel" = 462058435;
      "Microsoft Outlook" = 985367838;
      "RunCat Neo" = 6757801838;
    };
  };
}
