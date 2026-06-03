# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal macOS dotfiles. Configs under `home/` mirror a path inside `$HOME` and are deployed via `install.sh` symlinks; the repo is **mid-migration to Nix** (flake + home-manager), so a growing subset is instead deployed declaratively from `nix/` via home-manager. Both mechanisms coexist.

## Install / deploy

```sh
./install.sh                       # (re)create symlinks from home/ into $HOME
brew bundle --file=~/Brewfile      # after install.sh has linked the Brewfile
home-manager switch --flake .#aki  # apply the nix/home-manager-managed configs
```

`install.sh` symlinks each top-level entry in `home/` to the same name under `$HOME`. **Exception:** `home/.config/` is not linked wholesale — its children are linked individually into `$HOME/.config/` so that unmanaged tools already using `~/.config` keep working. Existing non-symlink files are moved aside to `*.backup` before linking; existing symlinks are replaced.

When adding a new config, place it at the path it should appear under `$HOME` (e.g. `home/.config/foo/bar` → `~/.config/foo/bar`) and re-run `install.sh`. For configs already migrated to home-manager, edit `nix/home.nix` (or files it references) and run `home-manager switch` instead — do **not** also add a `home/` copy, or the two will fight over the same `~` path.

## Nix / home-manager

`flake.nix` (repo root) defines `homeConfigurations.aki` → `nix/home.nix` (`aarch64-darwin`, user `aki`, stateVersion `25.11`). A 4-phase gradual migration off Homebrew/`install.sh` is in progress. Currently home-manager-managed:

- **CLI tools** `ripgrep` / `fd` / `jq` — `home.packages` (removed from Brewfile).
- **git** — `programs.git` in `nix/home.nix`. `settings` holds the config; `ignores`/`attributes` generate `~/.config/git/{ignore,attributes}`; hooks live in `nix/git/hooks/` and are linked via `xdg.configFile."git/hooks"`. `core.excludesfile` is intentionally unset so git reads the default `~/.config/git/ignore`.
- **starship** — `programs.starship`, settings read from `nix/starship.toml` via `builtins.fromTOML`.

`git` and `starship` were removed from the Brewfile (nix is now their source of truth) but their brew binaries may remain installed as transitive dependencies; PATH order decides which runs until the shell config is migrated.

## Layout worth knowing

- `home/Brewfile` — package manifest; symlinked to `~/Brewfile`. After editing run `brew bundle --file=~/Brewfile`.
- `home/.zshrc` — entry point; delegates plugin loading to `sheldon` (config in `home/.config/sheldon/plugins.toml`). Prompt is `starship` (config now nix-managed, see above), runtime manager is `mise`. Defines `gf`/`cf`/`of` fzf helpers. Still install.sh-symlinked (not yet migrated to home-manager).
- `home/.config/nvim/` — Neovim config. `init.lua` → `config.options` + `config.lazy`. `lazy.lua` auto-imports every file under `lua/plugins/*.lua`, so adding a plugin = adding one file there (no central registry to update). `lazy-lock.json` is committed.
- `nix/git/hooks/` — git hooks, deployed to `~/.config/git/hooks/` by home-manager and run for every repo on this machine via `core.hooksPath`. `pre-commit` is Maven-specific (license plugin + third-party-report regeneration) and silently no-ops when `pom.xml` / `license.txt` are absent.
- `home/.claude/skills/` — user-scoped Claude Code slash commands. Each subdir contains a `SKILL.md` with YAML frontmatter (`name`, `description`, `argument-hint`, `disable-model-invocation`); `$0`, `$1`, … are the positional args passed to the slash command.

## Conventions

- Commit messages in this repo are lowercase, imperative, and scope-terse (e.g. `add fzf and ghq to Brewfile`, `update tmux config`). Match that style.
- Don't commit anything under `home/.claude/` other than `skills/` and `settings.json` — the rest is runtime state (`backups/`, `cache/`, `projects/`, `history.jsonl`, credentials, etc.) and must stay untracked.
