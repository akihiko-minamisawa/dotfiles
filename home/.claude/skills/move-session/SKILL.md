---
name: move-session
description: Copy (or move) the current Claude Code session JSONL to another project directory so the conversation can be resumed in a different cwd.
argument-hint: "<target-dir> [session-id|latest] [--move]"
disable-model-invocation: true
---

# Move Claude Code Session Between Project Dirs

Claude Code stores each conversation as a `.jsonl` file under `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`. The directory name is the absolute cwd with `/` and `.` replaced by `-`. Sessions are scoped per project, so to resume a conversation in a different directory, the JSONL must be relocated to that project's encoded dir, then `claude --resume` from there.

## Usage

```
/move-session <target-dir> [session-id|latest] [--move]
```

- `$0` — target directory (absolute or `~`-relative). Required.
- `$1` — session UUID or `latest` (default).
- `$2` — `--move` to actually `mv` the file. Default is `cp` (safer; does not touch the source).

If `$0` is empty, print this usage and stop:

```
Usage: /move-session <target-dir> [session-id|latest] [--move]

  <target-dir>              Project dir to move the session into (e.g. ~/dev/src/github.com/foo/bar)
  [session-id|latest]       Session UUID or "latest" (default = latest)
  [--move]                  Actually move (mv). Default is copy (cp).
```

## Steps

Run the following bash. Do not paraphrase the logic — execute it.

```bash
set -euo pipefail

TARGET_DIR_RAW="$0"
SESSION_ARG="${1:-latest}"
MODE_FLAG="${2:-}"

# 1. Resolve target absolute path (allow non-existent target)
TARGET_DIR=$(python3 -c "import os,sys; print(os.path.abspath(os.path.expanduser(sys.argv[1])))" "$TARGET_DIR_RAW")

# 2. Encode project dir names: / and . -> -
encode() { printf '%s' "$1" | sed 's|[/.]|-|g'; }
SRC_PROJECT=$(encode "$PWD")
DST_PROJECT=$(encode "$TARGET_DIR")
SRC_DIR="$HOME/.claude/projects/$SRC_PROJECT"
DST_DIR="$HOME/.claude/projects/$DST_PROJECT"

[ -d "$SRC_DIR" ] || { echo "source project dir not found: $SRC_DIR"; exit 1; }

# 3. Pick session file
if [ "$SESSION_ARG" = "latest" ] || [ -z "$SESSION_ARG" ]; then
  SESSION_FILE=$(ls -t "$SRC_DIR"/*.jsonl 2>/dev/null | head -1)
  [ -n "$SESSION_FILE" ] || { echo "no session files in $SRC_DIR"; exit 1; }
else
  SESSION_FILE="$SRC_DIR/${SESSION_ARG%.jsonl}.jsonl"
  [ -f "$SESSION_FILE" ] || { echo "session not found: $SESSION_FILE"; exit 1; }
fi

# 4. Choose op
OP="cp"
[ "$MODE_FLAG" = "--move" ] && OP="mv"

# 5. Ensure target project dir exists, abort if destination file already there
mkdir -p "$DST_DIR"
DST_FILE="$DST_DIR/$(basename "$SESSION_FILE")"
[ -e "$DST_FILE" ] && { echo "destination already exists: $DST_FILE"; exit 1; }

# 6. Do it
$OP "$SESSION_FILE" "$DST_FILE"

# 7. Report
echo
echo "session: $(basename "$SESSION_FILE")"
echo "  from:  $SRC_DIR"
echo "  to:    $DST_DIR"
echo "  op:    $OP"
echo
echo "Next steps to resume:"
echo "  cd $TARGET_DIR"
echo "  claude --resume"
```

## Notes

- `cp` (default) leaves the source intact. After resuming and confirming the new location works, the user can delete the original via `rm "$SRC_DIR/<id>.jsonl"`.
- Resuming requires exiting the current `claude` first (otherwise live writes will keep extending the source file, not the moved copy).
- The encoded path swap is `/` and `.` → `-`. Hyphens and underscores in path components are kept as-is.
- If the target project directory doesn't exist on disk yet, this skill still creates the `~/.claude/projects/<encoded>/` entry; `claude --resume` from any matching cwd will then see the session.
