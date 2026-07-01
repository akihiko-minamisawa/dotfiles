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
}
