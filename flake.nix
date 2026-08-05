{
  description = "aki's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Extra nixpkgs revisions pinned for the per-project devShells below —
    # exact runtime patch versions that the main (moving) nixpkgs no longer
    # carries. Find a rev for a version at https://www.nixhub.io.
    # 2026-05 snapshot: nodejs_24 24.14.1 (nissan-vpa .nvmrc). Same rev the
    # main input was locked to when this pin was added; kept separate so
    # `nix flake update` can't drift the project shell off its pinned patch.
    nixpkgs-2605.url = "github:NixOS/nixpkgs/68a8af93ff4297686cb68880845e61e5e2e41d92";
    # 2025-05 snapshot: temurin-bin-17 17.0.14 + maven 3.9.9 (BFF),
    # nodejs_20 20.19.0 (nissan-vpa-idp-proxy .nvmrc)
    nixpkgs-2505.url = "github:NixOS/nixpkgs/b3582c75c7f21ce0b429898980eddbbf05c68e55";
    # 2023-09 snapshot: nodejs_20 20.8.0 (ngx-OMAKASE .node-version)
    nixpkgs-2309.url = "github:NixOS/nixpkgs/c182df2e68bd97deb32c7e4765adfbbbcaf75b60";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # hunk (hunk.dev): review-first terminal diff viewer. Not in nixpkgs yet,
    # so it comes straight from the upstream flake (main = beta line, source
    # build via bun2nix). Ships a home-manager module — wired into
    # homeConfigurations below, configured as programs.hunk in nix/home.nix.
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-2605, nixpkgs-2505, nixpkgs-2309, nix-darwin, home-manager, hunk, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs2605 = nixpkgs-2605.legacyPackages.${system};
      pkgs2505 = nixpkgs-2505.legacyPackages.${system};
      pkgs2309 = nixpkgs-2309.legacyPackages.${system};
    in {
      homeConfigurations.aki = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        # hunk's module defaults programs.hunk.package to the flake's own
        # build, so home.nix only has to flip programs.hunk.enable.
        modules = [ ./nix/home.nix hunk.homeManagerModules.default ];
      };

      darwinConfigurations."minamisawa-macbook" = nix-darwin.lib.darwinSystem {
        modules = [ ./nix/darwin.nix ];
      };

      # Per-project toolchains (replaced mise). A work repo opts in with a
      # one-line .envrc — `use flake <this repo>#<shell>` — which direnv
      # activates on cd (.envrc and .direnv/ are globally gitignored, so
      # A-CMS repos stay clean). Runtimes are pinned to the exact patch via
      # the dated nixpkgs inputs above; `nix flake update` moves the main
      # nixpkgs but never these shells.
      devShells.${system} = {
        # JP BFF services (nissan-bff-repos): pom.xml java.version=17.
        # Mirrors the retired mise toolchain: temurin 17.0.14, maven 3.9.9.
        bff = pkgs.mkShell {
          packages = [ pkgs2505.temurin-bin-17 pkgs2505.maven ];
          JAVA_HOME = pkgs2505.temurin-bin-17.home;
        };
        # nissan-vpa: .nvmrc 24.14.1
        vpa = pkgs.mkShell { packages = [ pkgs2605.nodejs_24 ]; };
        # nissan-vpa-idp-proxy: .nvmrc 20.19.0
        vpa-idp-proxy = pkgs.mkShell { packages = [ pkgs2505.nodejs_20 ]; };
        # ngx-OMAKASE: .node-version 20.8.0
        ngx-omakase = pkgs.mkShell { packages = [ pkgs2309.nodejs_20 ]; };
        # Go work: no repo pins a patch version today, so track main nixpkgs
        go = pkgs.mkShell { packages = [ pkgs.go ]; };
      };
    };
}
