{
  description = "aki's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Dated nixpkgs pins for the devShells below: exact runtime patches the
    # moving nixpkgs no longer carries (find a rev at https://www.nixhub.io).
    # Kept separate so `nix flake update` can't drift a project shell.
    # 2026-05 snapshot: nodejs_24 24.14.1 (nissan-vpa .nvmrc)
    nixpkgs-2605.url = "github:NixOS/nixpkgs/68a8af93ff4297686cb68880845e61e5e2e41d92";
    # 2025-05 snapshot: temurin-bin-17 17.0.14 + maven 3.9.9 (BFF),
    # nodejs_20 20.19.0 (nissan-vpa-idp-proxy .nvmrc)
    nixpkgs-2505.url = "github:NixOS/nixpkgs/b3582c75c7f21ce0b429898980eddbbf05c68e55";
    # 2023-09 snapshot: nodejs_20 20.8.0 (ngx-OMAKASE .node-version)
    nixpkgs-2309.url = "github:NixOS/nixpkgs/c182df2e68bd97deb32c7e4765adfbbbcaf75b60";
    # 2024-06 snapshot: terraform 1.8.5 (terraform devShell below)
    nixpkgs-2406.url = "github:NixOS/nixpkgs/b60793b86201040d9dee019a05089a9150d08b5b";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # hunk (hunk.dev): terminal diff viewer. Not in nixpkgs yet, so consumed
    # from the upstream flake; its home-manager module is wired in below.
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-2605, nixpkgs-2505, nixpkgs-2406, nixpkgs-2309, nix-darwin, home-manager, hunk, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs2605 = nixpkgs-2605.legacyPackages.${system};
      pkgs2505 = nixpkgs-2505.legacyPackages.${system};
      pkgs2309 = nixpkgs-2309.legacyPackages.${system};
      # plain import: terraform is unfree (BUSL), legacyPackages can't allow it
      pkgs2406 = import nixpkgs-2406 {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      homeConfigurations.aki = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./nix/home.nix hunk.homeManagerModules.default ];
      };

      darwinConfigurations."minamisawa-macbook" = nix-darwin.lib.darwinSystem {
        modules = [ ./nix/darwin.nix ];
      };

      # Per-project toolchains. A work repo opts in with a one-line .envrc —
      # `use flake <this repo>#<shell>` — activated by direnv on cd (.envrc
      # and .direnv/ are globally gitignored, so A-CMS repos stay clean).
      devShells.${system} = {
        # JP BFF services (nissan-bff-repos): pom.xml java.version=17
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
        # No repo carries .tf files today, so no .envrc opts in anywhere —
        # reach it ad hoc with `nix develop <this flake>#terraform`.
        terraform = pkgs.mkShell { packages = [ pkgs2406.terraform ]; };
      };
    };
}
