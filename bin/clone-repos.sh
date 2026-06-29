#!/usr/bin/env bash
# Clone all GitHub repos the user works with into ~/dev/src/github.com/<owner>/<repo>.
# Idempotent: existing clones are skipped (a `git fetch` is run instead).
# Requires: gh (authenticated), git over ssh.
#
# NOTE: repos WITHOUT a GitHub remote (e.g. `notes`) are NOT here — they are
# local-only and must be restored by manual copy (see SETUP.md).
set -euo pipefail

OWNERS=("A-CMS" "akihiko-minamisawa")
BASE="$HOME/dev/src/github.com"

command -v gh >/dev/null || { echo "gh not found. Install & 'gh auth login' first." >&2; exit 1; }

for owner in "${OWNERS[@]}"; do
  echo "==> Enumerating $owner ..."
  # nameWithOwner like "A-CMS/nissan-kamereon-service"
  mapfile -t repos < <(gh repo list "$owner" --no-archived --limit 500 --json nameWithOwner -q '.[].nameWithOwner')
  echo "    ${#repos[@]} repos"
  for nwo in "${repos[@]}"; do
    name="${nwo#*/}"
    dest="$BASE/$owner/$name"
    if [ -d "$dest/.git" ]; then
      echo "    [skip] $nwo (exists)"
      git -C "$dest" fetch --quiet --all || true
    else
      echo "    [clone] $nwo"
      mkdir -p "$BASE/$owner"
      gh repo clone "$nwo" "$dest" -- --quiet || echo "    [warn] failed: $nwo"
    fi
  done
done

echo "Done. (local-only repos like 'notes' are NOT cloned — restore by manual copy.)"
