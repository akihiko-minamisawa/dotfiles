---
name: vim-coach
description: Analyze nvim keystroke logs (~/.local/state/nvim/keylog/) and return concrete advice on editing habits for getting better at vim. Use for requests like "give me vim advice", "analyze my keylog", or "I want to use vim more efficiently".
argument-hint: "[days or a question (default: last 3 days)]"
---

# Vim Coach: keystroke log analysis

Read the logs written by the keylogger wired into nvim
(`~/.config/nvim/lua/config/keylog.lua`), find habits, and give concrete
advice for getting better at vim. Respond in Japanese.

If `$ARGUMENTS` is a number, analyze that many days; if it is a question,
focus the analysis on that angle. Default: the last 3 days.

## Reading the logs

- Location: `~/.local/state/nvim/keylog/YYYY-MM-DD.log` (logs older than 30 days are deleted automatically)
- Format: `HH:MM:SS [mode] keys` (one line = a run of input in the same mode with gaps under 2 seconds, max 200 keys)
- mode is the value of `nvim_get_mode().mode`: `n`=normal, `i`=insert, `v`/`V`/`^V`=visual, `c`=cmdline, `no`=operator-pending, `t`=terminal, etc.
- `·` is a masked character typed in insert/replace/terminal mode. Content is
  invisible by design, but run length still measures typing volume (a long
  `····` run after `ciw` tells a different story than after `i`)
- cmdline mode is NOT masked — `:w` frequency, `:%s` usage and Ex habits are
  directly visible
- Special keys use keytrans notation like `<Esc>` `<BS>` `<CR>` `<C-w>`
- Keys are concatenated without separators (`jjjj`, `<Esc><Esc>`), so plain
  `grep` on patterns like `jjj` works

Handy aggregations (adjust file globs to the target period):

```bash
# time spent per mode (rough proxy: lines per mode)
grep -oh '\[[^]]*\]' ~/.local/state/nvim/keylog/*.log | sort | uniq -c | sort -rn
# arrow-key dependence
grep -oh '<\(Up\|Down\|Left\|Right\)>' ~/.local/state/nvim/keylog/*.log | sort | uniq -c
# long j/k runs per day
for f in ~/.local/state/nvim/keylog/*.log; do printf '%s ' "$f"; grep -c 'jjj\|kkk' "$f"; done
```

## Steps

1. Read the logs for the target period. If they are large, aggregate with Bash (`grep -c` / `awk` etc.)
2. Check the user's actual config before advising:
   - `~/.config/nvim/` (the real files live in the dotfiles repo; leader is `<Space>`)
   - Never propose keymaps or plugins that already exist as if they were missing
3. Look for habits along these lines (examples, not an exhaustive list):
   - runs of `jjjj` / `kkkk` / `hhhh` / `llll` → counts (`5j`), relativenumber jumps, `f`/`t`, `/` search, `{` `}`, `<C-d>`/`<C-u>`
   - arrow key usage
   - repeated `x` or `dd`+`i` → operator + text object (`dw` `ciw` `ci"` `ct)`)
   - short `i`→`<Esc>`→move→`i` cycles → `A` `I` `o` `O` `ea`
   - `<BS>` runs inside insert mode → `<C-w>` `<C-u>`, or leave insert and edit
   - `:w` frequency, `u` runs, repeating the same edit by hand → `.` repeat, macros, `:g`
   - visual select → operate, where a bare operator would do
   - unused territory: registers, marks, `*`/`#`, `%`, text objects, existing leader maps
4. Count occurrences and cite evidence (e.g. "42 runs of 3+ `j` today alone")
5. For multi-day periods, compare the first and second half of the period on
   the flagged patterns — call out habits that are already improving (or a
   previous drill that clearly stuck) before piling on new advice

## Output format

- **Good habits**: efficient operations already in use (1–3)
- **Top 3–5 habits to fix**: evidence (counts, actual log lines) paired with what to type instead
- **This week's drill**: exactly one, small enough to fix consciously
- **Config suggestions** (if any): keymap or plugin changes. Get the user's explicit approval before applying anything to the dotfiles

## Notes

- Logs contain physical input only (keys produced by mapping expansion are absent). Lines starting with `<Space>` are leader operations
- Mouse and scroll events are filtered out entirely — heavy mouse use is a
  blind spot the logs cannot reveal, so never conclude "no mouse dependence"
  from them
- Recording is toggled with `:Keylog`, so a quiet period does not necessarily mean vim wasn't used
- Don't overload the advice; keep it to an amount that can actually become habit
