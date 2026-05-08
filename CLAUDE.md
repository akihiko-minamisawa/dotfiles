# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal macOS dotfiles. Everything under `home/` mirrors a path inside `$HOME` and is deployed via symlinks.

## Install / deploy

```sh
./install.sh            # (re)create symlinks from home/ into $HOME
brew bundle --file=~/Brewfile   # after install.sh has linked the Brewfile
```

`install.sh` symlinks each top-level entry in `home/` to the same name under `$HOME`. **Exception:** `home/.config/` is not linked wholesale — its children are linked individually into `$HOME/.config/` so that unmanaged tools already using `~/.config` keep working. Existing non-symlink files are moved aside to `*.backup` before linking; existing symlinks are replaced.

When adding a new config, place it at the path it should appear under `$HOME` (e.g. `home/.config/foo/bar` → `~/.config/foo/bar`) and re-run `install.sh`.

## Layout worth knowing

- `home/Brewfile` — package manifest; symlinked to `~/Brewfile`. After editing run `brew bundle --file=~/Brewfile`.
- `home/.zshrc` — entry point; delegates plugin loading to `sheldon` (config in `home/.config/sheldon/plugins.toml`). Prompt is `starship`, runtime manager is `mise`. Defines `gf`/`cf`/`of` fzf helpers.
- `home/.config/nvim/` — Neovim config. `init.lua` → `config.options` + `config.lazy`. `lazy.lua` auto-imports every file under `lua/plugins/*.lua`, so adding a plugin = adding one file there (no central registry to update). `lazy-lock.json` is committed.
- `home/.config/git/` — git config. `core.hooksPath` points at `home/.config/git/hooks/`, so scripts dropped there run for every repo on this machine. `pre-commit` is Maven-specific (license plugin + third-party-report regeneration) and silently no-ops when `pom.xml` / `license.txt` are absent.
- `home/.config/git/ignore` — global gitignore (linked via `core.excludesfile`, historically `~/.gitignore_global`).
- `home/.claude/skills/` — user-scoped Claude Code slash commands. Each subdir contains a `SKILL.md` with YAML frontmatter (`name`, `description`, `argument-hint`, `disable-model-invocation`); `$0`, `$1`, … are the positional args passed to the slash command.

## Conventions

- Commit messages in this repo are lowercase, imperative, and scope-terse (e.g. `add fzf and ghq to Brewfile`, `update tmux config`). Match that style.
- Don't commit anything under `home/.claude/` other than `skills/` and `settings.json` — the rest is runtime state (`backups/`, `cache/`, `projects/`, `history.jsonl`, credentials, etc.) and must stay untracked.
