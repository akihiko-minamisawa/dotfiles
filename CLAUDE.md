# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal macOS dotfiles, fully declarative via Nix. Two entry points own everything:

```sh
home-manager switch --flake .#aki                        # user env: packages, shell, config symlinks
sudo darwin-rebuild switch --flake .#minamisawa-macbook  # system + Homebrew (brews/casks/mas)
```

`install.sh` and the hand-maintained `home/Brewfile` are retired. New-Mac bootstrap lives in `SETUP.md`.

## Where things are declared

- **CLI tools** → `home.packages` in `nix/home.nix` (ripgrep, fd, jq, fzf, gh, ghq, lazygit, tree, yq-go, zk, git-filter-repo, go-migrate, kubelogin, azure-cli, gemini-cli, yarn, neovim, tmux, zsh-completions, podman, podman-compose, vfkit, qemu, flyway, …).
- **Homebrew inventory** → `homebrew` block in `nix/darwin.nix`: brews deliberately kept on brew (gdal/postgis geo stack, brew services like `postgresql@14`/redis/rabbitmq, erlang as rabbitmq's dependency, mysql-client, gnupg, mas), all casks, all Mac App Store apps. `onActivation.cleanup = "uninstall"` — **anything installed with ad-hoc `brew install` is removed on the next darwin switch**; declare it here instead.
- **Config files** → `xdg.configFile` in `nix/home.nix` as **out-of-store symlinks** into `home/.config/` (ghostty, nix, nvim, tmux, wezterm, zk), plus `home.file.".claude"` for `~/.claude`. Editing files under `home/` takes effect immediately — no switch needed. nvim must stay out-of-store (lazy.nvim writes `lazy-lock.json` into the config dir). `.claude` has `force = true` because a live Claude Code process recreates `~/.claude` within seconds if it goes missing.
- **zsh / git / starship / mise** → home-manager modules in `nix/home.nix` (`programs.*`). zsh plugins (autosuggestions, syntax-highlighting, completions) load via home-manager, synchronously. `~/.zshrc` is generated; the fzf helpers `gf`/`cf`/`of`, machine-specific PATH exports, and the Azure CLI completion live in `initContent`.
- **darwin system** → `nix/darwin.nix`. Intentionally minimal: `nix.enable = false` (official daemon owns `/etc/nix/nix.conf`, preserving the `ssl-cert-file` fix), `programs.zsh/bash.enable = false` (home-manager owns the shell; avoids a second compinit from `/etc/zshrc`).

When adding a new tool: prefer `home.packages`; use `homebrew.brews`/`casks` only for GUI apps, brew services, or build-library stacks. When adding a config, put the files under `home/.config/<name>/` and add one `live "<name>"` line to `xdg.configFile`.

## PATH ordering (deliberate)

`.zshrc` prepends `$HOME/.nix-profile/bin:/run/current-system/sw/bin` — macOS `path_helper` would otherwise leave the nix profile last and let `/usr/bin`/brew copies shadow declared packages. This lives in `.zshrc` (not `home.sessionPath`/`.zshenv`) so it survives shells inheriting a stale environment, e.g. panes of a long-running tmux server.

## Layout worth knowing

- `home/.config/nvim/` — Neovim config. `init.lua` → `config.options` + `config.lazy`. `lazy.lua` auto-imports every file under `lua/plugins/*.lua`, so adding a plugin = adding one file there (no central registry to update). `lazy-lock.json` is committed.
- `nix/git/hooks/` — git hooks, deployed to `~/.config/git/hooks/` by home-manager and run for every repo on this machine via `core.hooksPath`. `pre-commit` is Maven-specific (license plugin + third-party-report regeneration) and silently no-ops when `pom.xml` / `license.txt` are absent.
- `home/.claude/skills/` — user-scoped Claude Code slash commands. Each subdir contains a `SKILL.md` with YAML frontmatter (`name`, `description`, `argument-hint`, `disable-model-invocation`); `$0`, `$1`, … are the positional args passed to the slash command.
- `bin/clone-repos.sh` — idempotent bulk clone of A-CMS/personal repos (used by SETUP.md).

## Conventions

- Commit messages in this repo are lowercase, imperative, and scope-terse (e.g. `add fzf to home.packages`, `update tmux config`). Match that style.
- Don't commit anything under `home/.claude/` other than `skills/` and `settings.json` — the rest is runtime state (`backups/`, `cache/`, `projects/`, `history.jsonl`, credentials, etc.) and must stay untracked.
