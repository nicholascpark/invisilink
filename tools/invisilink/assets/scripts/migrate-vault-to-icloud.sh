#!/bin/bash
# migrate-vault-to-icloud.sh — idempotent migration of the parent vault from
# repo-local ./knowledge/ to an iCloud Drive container at
# ~/Library/Mobile Documents/com~apple~CloudDocs/business-machine-vault/
#
# This is a COPY, not a MOVE. The original ./knowledge/ remains in place and
# serves as fallback_uri. A future slice can remove it once iCloud is proven.
#
# The script is idempotent: each step is guarded by a marker in
# {container}/archives/schema-migrations/pre-icloud-to-icloud/MIGRATION_STATE.json.
# Running twice = same end state. Running after commit = no-op.
#
# Preconditions:
#   - .claude/knowledge-config.json exists with device_id set
#   - knowledge/ directory exists with schema.md, config.json, log.md,
#     index.md, hot.md, raw/, wiki/, lineage/, meta/
#   - jq, shasum, and the knowledge-paths.sh helper are available
#
# Environment overrides (for testing):
#   ICLOUD_CONTAINER   — alternate container path (default: the real iCloud path)
#   MIGRATION_DATE     — snapshot dir date (default: today, YYYY-MM-DD)
#
# Parent-only. Ventures never run this.

set -euo pipefail

# ---------- Resolve paths ----------

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../../.." && pwd)
HELPER="$SCRIPT_DIR/knowledge-paths.sh"

if [ ! -x "$HELPER" ]; then
  echo "ERROR: knowledge-paths.sh not found or not executable at $HELPER" >&2
  exit 1
fi

ICLOUD_CONTAINER="${ICLOUD_CONTAINER:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/business-machine-vault}"
ICLOUD_VAULT="$ICLOUD_CONTAINER/parent"
ICLOUD_META="$ICLOUD_CONTAINER/meta"
ICLOUD_INBOX="$ICLOUD_CONTAINER/inbox"
ICLOUD_ARCHIVES="$ICLOUD_CONTAINER/archives"
ICLOUD_EXPORTS="$ICLOUD_CONTAINER/exports"

MIGRATION_DATE="${MIGRATION_DATE:-$(date +%Y-%m-%d)}"
SNAPSHOT_DIR="$ICLOUD_ARCHIVES/$MIGRATION_DATE-pre-migration"
MIGRATION_STATE="$ICLOUD_ARCHIVES/schema-migrations/pre-icloud-to-icloud/MIGRATION_STATE.json"

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

# ---------- State marker helpers ----------

step_done() {
  local step="$1"
  [ -f "$MIGRATION_STATE" ] && jq -e --arg s "$step" '.steps[$s] == true' "$MIGRATION_STATE" >/dev/null 2>&1
}

init_state_if_needed() {
  if [ ! -f "$MIGRATION_STATE" ]; then
    mkdir -p "$(dirname "$MIGRATION_STATE")"
    local device_id
    device_id=$("$HELPER" device)
    jq -n \
      --arg d "$device_id" \
      --arg started "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      '{steps: {}, committed: false, started_at: $started, started_by: $d}' \
      > "$MIGRATION_STATE.tmp"
    mv "$MIGRATION_STATE.tmp" "$MIGRATION_STATE"
  fi
}

mark_step() {
  local step="$1"
  init_state_if_needed
  jq --arg s "$step" --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '.steps[$s] = true | .last_step_at = $t' "$MIGRATION_STATE" > "$MIGRATION_STATE.tmp"
  mv "$MIGRATION_STATE.tmp" "$MIGRATION_STATE"
  log "✓ $step"
}

# ---------- Content-addressable copy ----------

# Copy a single file. Idempotent: if destination exists with same hash, skip.
# Different hash aborts with a clear error.
copy_file() {
  local src="$1" dest="$2"
  if [ ! -f "$src" ]; then
    log "  skip $src (source does not exist)"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ]; then
    local src_hash dest_hash
    src_hash=$(shasum -a 256 "$src" | awk '{print $1}')
    dest_hash=$(shasum -a 256 "$dest" | awk '{print $1}')
    if [ "$src_hash" = "$dest_hash" ]; then
      return 0
    else
      log "  ABORT: $dest diverged from $src"
      log "    src_hash:  $src_hash"
      log "    dest_hash: $dest_hash"
      log "    resolve manually or restore from snapshot at $SNAPSHOT_DIR"
      return 1
    fi
  fi
  local tmp="$dest.tmp.$$"
  cp "$src" "$tmp"
  mv -f "$tmp" "$dest"
  return 0
}

# Copy a directory recursively, file by file.
copy_dir() {
  local src="$1" dest="$2"
  if [ ! -d "$src" ]; then
    log "  skip $src (directory does not exist)"
    return 0
  fi
  mkdir -p "$dest"
  # Use find -print0 + xargs to handle spaces in filenames and avoid subshell issues
  while IFS= read -r -d '' dir; do
    local rel="${dir#$src}"
    rel="${rel#/}"
    [ -z "$rel" ] && continue
    mkdir -p "$dest/$rel"
  done < <(find "$src" -type d -print0)
  while IFS= read -r -d '' file; do
    local rel="${file#$src}"
    rel="${rel#/}"
    copy_file "$file" "$dest/$rel" || return 1
  done < <(find "$src" -type f -print0)
  return 0
}

# ---------- Main ----------

log "=== migrate-vault-to-icloud.sh ==="
log "repo root: $REPO_ROOT"
log "source:    $REPO_ROOT/knowledge"
log "container: $ICLOUD_CONTAINER"
log "vault:     $ICLOUD_VAULT"
log "snapshot:  $SNAPSHOT_DIR"
log "state:     $MIGRATION_STATE"

# Preflight

DEVICE_ID=$("$HELPER" device)
if [ -z "$DEVICE_ID" ]; then
  log "FAIL: bootstrap config missing device_id"
  exit 1
fi
log "device_id: $DEVICE_ID"

if [ ! -d "$REPO_ROOT/knowledge" ]; then
  log "FAIL: source vault not found at $REPO_ROOT/knowledge"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  log "FAIL: jq not installed"
  exit 1
fi

# Check if already committed

if [ -f "$MIGRATION_STATE" ]; then
  if jq -e '.committed == true' "$MIGRATION_STATE" >/dev/null 2>&1; then
    committed_at=$(jq -r '.committed_at // "unknown"' "$MIGRATION_STATE")
    log "migration already committed at $committed_at — nothing to do"
    log "(rerun with clean $MIGRATION_STATE to force)"
    exit 0
  else
    log "resuming previous incomplete migration"
  fi
fi

# Step 1: Create container structure

if ! step_done create_container; then
  log "creating container at $ICLOUD_CONTAINER"
  mkdir -p "$ICLOUD_VAULT" "$ICLOUD_META" "$ICLOUD_INBOX" "$ICLOUD_ARCHIVES" "$ICLOUD_EXPORTS"
  mark_step create_container
fi

# Step 2: Pre-migration snapshot (must happen before any destructive operation;
# this migration is copy-only so it's a belt-and-suspenders safety net)

if ! step_done snapshot; then
  log "creating snapshot at $SNAPSHOT_DIR"
  copy_dir "$REPO_ROOT/knowledge" "$SNAPSHOT_DIR/knowledge"
  # Also snapshot the bootstrap config before we rewrite it
  copy_file "$REPO_ROOT/.claude/knowledge-config.json" "$SNAPSHOT_DIR/knowledge-config.json"
  mark_step snapshot
fi

# Step 3: Copy vault contents to iCloud parent/

if ! step_done copy_parent; then
  log "copying vault files to $ICLOUD_VAULT"
  for file in config.json schema.md index.md log.md hot.md; do
    copy_file "$REPO_ROOT/knowledge/$file" "$ICLOUD_VAULT/$file"
  done
  copy_dir "$REPO_ROOT/knowledge/raw" "$ICLOUD_VAULT/raw"
  copy_dir "$REPO_ROOT/knowledge/wiki" "$ICLOUD_VAULT/wiki"
  copy_dir "$REPO_ROOT/knowledge/lineage" "$ICLOUD_VAULT/lineage"
  mark_step copy_parent
fi

# Step 4: Copy meta files to container meta/ (container-level, not vault-level)

if ! step_done copy_meta; then
  log "copying meta files to $ICLOUD_META"
  copy_file "$REPO_ROOT/knowledge/meta/capabilities.json" "$ICLOUD_META/capabilities.json"
  copy_file "$REPO_ROOT/knowledge/meta/devices.json" "$ICLOUD_META/devices.json"
  mark_step copy_meta
fi

# Step 5: Populate inbox README and exports .gitkeep

if ! step_done create_peers_content; then
  if [ ! -f "$ICLOUD_INBOX/README.md" ]; then
    cat > "$ICLOUD_INBOX/README.md.tmp.$$" <<'INBOX_README'
# Inbox

External deposits awaiting promotion to parent/raw/. Drop markdown files here for manual ingestion.

The librarian promotes files from inbox/ to parent/raw/imports/ during normal cycles, after classification. Files in this directory are NOT yet part of the knowledge graph — they are raw input awaiting processing.
INBOX_README
    mv "$ICLOUD_INBOX/README.md.tmp.$$" "$ICLOUD_INBOX/README.md"
  fi
  [ ! -f "$ICLOUD_EXPORTS/.gitkeep" ] && touch "$ICLOUD_EXPORTS/.gitkeep"
  mark_step create_peers_content
fi

# Step 6: Rewrite .claude/knowledge-config.json to point at iCloud

if ! step_done update_bootstrap; then
  log "updating bootstrap config"
  # Percent-encode spaces for URI form
  encoded_container=$(printf '%s' "$ICLOUD_CONTAINER" | sed 's/ /%20/g')
  encoded_vault=$(printf '%s' "$ICLOUD_VAULT" | sed 's/ /%20/g')
  new_container_uri="file://$encoded_container"
  new_vault_uri="file://$encoded_vault"
  bootstrap="$REPO_ROOT/.claude/knowledge-config.json"
  jq --arg c "$new_container_uri" --arg v "$new_vault_uri" \
    '.container_uri = $c | .vault_uri = $v' \
    "$bootstrap" > "$bootstrap.tmp.$$"
  mv -f "$bootstrap.tmp.$$" "$bootstrap"
  mark_step update_bootstrap
fi

# Step 7: Also update the vault config inside iCloud to match

if ! step_done update_vault_config; then
  log "updating vault config at $ICLOUD_VAULT/config.json"
  encoded_container=$(printf '%s' "$ICLOUD_CONTAINER" | sed 's/ /%20/g')
  encoded_vault=$(printf '%s' "$ICLOUD_VAULT" | sed 's/ /%20/g')
  new_container_uri="file://$encoded_container"
  new_vault_uri="file://$encoded_vault"
  vault_config="$ICLOUD_VAULT/config.json"
  jq --arg c "$new_container_uri" --arg v "$new_vault_uri" \
    '.container_uri = $c | .vault_uri = $v' \
    "$vault_config" > "$vault_config.tmp.$$"
  mv -f "$vault_config.tmp.$$" "$vault_config"
  mark_step update_vault_config
fi

# Step 8: Flip capability flags in iCloud capabilities.json

if ! step_done flip_capabilities; then
  log "flipping capability flags in iCloud capabilities.json"
  caps="$ICLOUD_META/capabilities.json"
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  jq --arg now "$now" '
    .capabilities.icloud_storage = true
    | .capabilities.uri_path_resolution = true
    | .capabilities.idempotent_migration = true
    | .declared_at = $now
    | .phase_status.phase_7_icloud_migration = "complete"
    | .driver_versions.path_resolver = "1.0.0"
  ' "$caps" > "$caps.tmp.$$"
  mv -f "$caps.tmp.$$" "$caps"
  mark_step flip_capabilities
fi

# Step 9: Append schema_migration log entry

if ! step_done append_log; then
  log "appending schema_migration entry to iCloud log.md"
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  log_path="$ICLOUD_VAULT/log.md"
  entry_tmp="$log_path.tmp.$$"
  cat "$log_path" > "$entry_tmp"
  cat >> "$entry_tmp" <<ENTRY

## $now — schema_migration

- **device:** $DEVICE_ID
- **operation:** schema_migration
- **affected_pages:** []
- **summary:** Migrated vault from repo-local ./knowledge to iCloud container at $ICLOUD_CONTAINER. Copy-mode migration; the repo-local ./knowledge remains as fallback_uri.
- **details:** Migration script: tools/invisilink/assets/scripts/migrate-vault-to-icloud.sh. Pre-migration snapshot: $SNAPSHOT_DIR. Capabilities flipped to true: icloud_storage, uri_path_resolution, idempotent_migration. State marker: $MIGRATION_STATE.
ENTRY
  mv -f "$entry_tmp" "$log_path"
  mark_step append_log
fi

# Step 10: Verify with knowledge-paths.sh check against the new container

if ! step_done verify; then
  log "verifying migration with knowledge-paths.sh check"
  if ! "$HELPER" check; then
    log "FAIL: post-migration check failed — NOT committing"
    exit 1
  fi
  mark_step verify
fi

# Commit

jq --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '.committed = true | .committed_at = $t' \
  "$MIGRATION_STATE" > "$MIGRATION_STATE.tmp"
mv -f "$MIGRATION_STATE.tmp" "$MIGRATION_STATE"

log ""
log "=== migration complete ==="
log ""
log "The vault has been copied to iCloud. The repo-local ./knowledge"
log "remains in place as fallback_uri for local resilience. It will"
log "not receive future librarian writes — all writes now go to iCloud."
log ""
log "MANUAL STEP: pin the container via Finder to prevent iCloud from"
log "dehydrating vault files into .icloud placeholders:"
log "  1. Open Finder"
log "  2. Navigate to $ICLOUD_CONTAINER"
log "  3. Right-click → 'Keep Downloaded'"
log ""
log "Rerun this script to verify idempotency. Expected output: 'already committed'."
