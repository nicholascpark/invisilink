#!/bin/bash
# notify-ventures.sh — drop infrastructure_upgrade_available packets into each
# live linked venture's umbilical/inbox/ when parent invisilink version changes.
#
# Wired from .git/hooks/post-commit (fires only when tools/invisilink/ changed).
# Fail-open: a venture that fails to receive the packet does not block others.
#
# Usage: notify-ventures.sh [--dry-run]

set -u

REPO_ROOT=$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_ROOT" ] && REPO_ROOT="/Users/nicholaspark/Documents/business-machine"

FLASH="$REPO_ROOT/tools/invisilink/flash.md"
CHANGELOG="$REPO_ROOT/tools/invisilink/CHANGELOG.md"
VENTURES="$REPO_ROOT/ventures.md"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

[ ! -f "$FLASH" ] && { echo "notify-ventures: $FLASH not found" >&2; exit 0; }
[ ! -f "$VENTURES" ] && { echo "notify-ventures: $VENTURES not found" >&2; exit 0; }

VERSION=$(grep -E '^version:' "$FLASH" | head -1 | sed 's/^version:[[:space:]]*//' | tr -d '"')
TODAY=$(date +%Y-%m-%d)

# Extract changelog body for current version — block between "## vVERSION" and next "## v" header.
CHANGELOG_BODY=$(awk -v v="$VERSION" '
  $0 ~ "^## v" v "( |$)" { capture=1; next }
  capture && /^## v[0-9]/ { capture=0 }
  capture { print }
' "$CHANGELOG" 2>/dev/null | sed '/^$/d' | head -20)
[ -z "$CHANGELOG_BODY" ] && CHANGELOG_BODY="See CHANGELOG.md in parent for full notes."

emit_packet() {
  local venture_name="$1"
  local repo_path="$2"
  local inbox="$repo_path/umbilical/inbox"

  if [ ! -d "$inbox" ]; then
    echo "  skip $venture_name — no $inbox"
    return 0
  fi

  # Sequence number: count existing INFRA packets for this venture today
  local seq=$(ls "$inbox"/INFRA-v${VERSION}-${TODAY}-*.md 2>/dev/null | wc -l | tr -d ' ')
  seq=$((seq + 1))
  local packet="$inbox/INFRA-v${VERSION}-${TODAY}-$(printf '%03d' $seq).md"

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] $venture_name ← $packet"
    return 0
  fi

  cat > "$packet" <<EOF
---
type: infrastructure_upgrade_available
version: "$VERSION"
urgency: low
created: $TODAY
source: parent post-commit hook
---

# Invisilink v$VERSION available

A new invisilink version is available on the parent. This venture is currently
on whatever version its \`umbilical/config.md\` records. Compare and run \`/flash\`
to pick up the latest.

## Changelog (v$VERSION)

$CHANGELOG_BODY

## Action

- Priority: low. No immediate action required — the human runs \`/flash\` when ready.
- Parent-spawned and gnosis-linked ventures both use \`/flash\` to upgrade.
- Running \`/flash\` re-stubs \`.claude/skills/flash/SKILL.md\` so the pointer stays current.
EOF
  echo "  ✓ $venture_name ← INFRA-v${VERSION}-${TODAY}-$(printf '%03d' $seq).md"
}

echo "notify-ventures: invisilink v$VERSION — fanning out packets"

# Walk ventures.md sections. Each venture is `## Name` followed by `- repo: <path>` and `- status: <state>`.
# Skip dead/graduated/removed entries. Expand ~ in paths.
awk '
  /^## / { name=$0; sub(/^## /, "", name); repo=""; state=""; next }
  /^- repo:/ { repo=$0; sub(/^- repo:[[:space:]]*/, "", repo); next }
  /^- status:/ { state=$0; sub(/^- status:[[:space:]]*/, "", state)
    if (name != "" && repo != "" && state != "") print name "\t" repo "\t" state
    name=""; repo=""; state=""
  }
' "$VENTURES" | while IFS=$'\t' read -r venture_name repo_path state; do
  # Skip dead, graduated, or removed ventures
  case "$state" in
    dead*|graduated*|removed*) continue ;;
  esac
  # Skip if repo path is not a local path (removed/github-only)
  case "$repo_path" in
    removed*|https://*|http://*) continue ;;
  esac
  # Expand ~
  expanded=$(eval echo "$repo_path" | sed 's:/$::')
  if [ ! -d "$expanded" ]; then
    echo "  skip $venture_name — $expanded not a dir"
    continue
  fi
  emit_packet "$venture_name" "$expanded"
done

echo "notify-ventures: done"
exit 0
