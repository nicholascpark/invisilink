#!/bin/bash
# knowledge-paths.sh — URI-shaped path resolution helper for the federated knowledge base
#
# Reads .claude/knowledge-config.json (bootstrap) and {vault_uri}/config.json (vault).
# Provides token resolution, reads, capability checks, and health validation.
#
# Usage:
#   knowledge-paths.sh resolve <token>     # expand a token to an absolute filesystem path
#   knowledge-paths.sh read <token>        # resolve + cat contents
#   knowledge-paths.sh capability <name>   # exit 0 if capability is true, 1 if false, 2 if unknown
#   knowledge-paths.sh check               # validate main URIs resolve
#   knowledge-paths.sh device              # print the configured device_id
#   knowledge-paths.sh bootstrap           # print the bootstrap config path
#
# Token grammar:
#   - "vault_uri", "container_uri", "fallback_uri", "device_id" — bootstrap config fields
#   - "schema_path", "index_path", "log_path", "raw_root", "wiki_root", etc. — vault config fields
#   - "{vault_uri}/some/path" — token substitution inside a path expression
#   - "{container_uri}/meta/capabilities.json" — same
#
# URI schemes supported:
#   - file:// (today)
#   - s3://, sqlite:// — reserved, errors with "scheme not yet supported"
#
# Exit codes:
#   0  — success
#   1  — capability false, or standard failure
#   2  — unknown capability, or invalid input
#   3  — URI scheme not supported
#   4  — file/path does not exist after resolution

set -euo pipefail

# ---------- Bootstrap discovery ----------

find_bootstrap() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/.claude/knowledge-config.json" ]; then
      printf '%s\n' "$dir/.claude/knowledge-config.json"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  printf 'ERROR: no .claude/knowledge-config.json found in %s or ancestors\n' "$PWD" >&2
  return 1
}

BOOTSTRAP_CONFIG=$(find_bootstrap) || exit 1
REPO_ROOT=$(cd "$(dirname "$(dirname "$BOOTSTRAP_CONFIG")")" && pwd)

CONTAINER_URI=$(jq -r '.container_uri // empty' "$BOOTSTRAP_CONFIG")
VAULT_URI=$(jq -r '.vault_uri // empty' "$BOOTSTRAP_CONFIG")
FALLBACK_URI=$(jq -r '.fallback_uri // empty' "$BOOTSTRAP_CONFIG")
DEVICE_ID=$(jq -r '.device_id // empty' "$BOOTSTRAP_CONFIG")

if [ -z "$VAULT_URI" ]; then
  echo "ERROR: bootstrap config missing vault_uri: $BOOTSTRAP_CONFIG" >&2
  exit 2
fi

# ---------- URI → filesystem path ----------

# Percent-decode a string (handles %20 → space, etc.)
url_decode() {
  local encoded="$1"
  printf '%b\n' "${encoded//%/\\x}"
}

# Convert a file:// URI to an absolute filesystem path. Errors on other schemes.
uri_to_path() {
  local uri="$1"
  case "$uri" in
    file://*)
      local path="${uri#file://}"
      path=$(url_decode "$path")
      # Relative path: resolve against REPO_ROOT
      case "$path" in
        ./*) path="$REPO_ROOT/${path#./}" ;;
        /*)  ;;  # already absolute
        *)   path="$REPO_ROOT/$path" ;;
      esac
      printf '%s\n' "$path"
      ;;
    s3://*|sqlite://*)
      echo "ERROR: URI scheme not yet supported: $uri" >&2
      echo "       Add a driver to knowledge-paths.sh to enable this scheme." >&2
      return 3
      ;;
    *)
      echo "ERROR: unknown URI scheme or invalid URI: $uri" >&2
      return 3
      ;;
  esac
}

# ---------- Token expansion ----------

# Expand {vault_uri} and {container_uri} tokens inside a string.
substitute_tokens() {
  local input="$1"
  input="${input//\{vault_uri\}/$VAULT_URI}"
  input="${input//\{container_uri\}/$CONTAINER_URI}"
  printf '%s\n' "$input"
}

# Resolve a token name or path expression to an absolute filesystem path.
resolve_token() {
  local token="$1"

  # Case 1: direct bootstrap field
  case "$token" in
    vault_uri)     uri_to_path "$VAULT_URI"; return $? ;;
    container_uri) uri_to_path "$CONTAINER_URI"; return $? ;;
    fallback_uri)  uri_to_path "$FALLBACK_URI"; return $? ;;
  esac

  # Case 2: contains {vault_uri} or {container_uri} — substitute then resolve as URI or path
  if [[ "$token" == *"{vault_uri}"* ]] || [[ "$token" == *"{container_uri}"* ]]; then
    local expanded
    expanded=$(substitute_tokens "$token")
    # After substitution, the result should start with file:// (or another scheme)
    case "$expanded" in
      file://*|s3://*|sqlite://*)
        uri_to_path "$expanded"
        return $?
        ;;
      *)
        # Token expansion produced a bare path (no scheme). Treat as a filesystem path.
        printf '%s\n' "$expanded"
        return 0
        ;;
    esac
  fi

  # Case 3: bare token name — look up in vault config, then resolve the value
  local vault_config_path
  vault_config_path=$(uri_to_path "$VAULT_URI/config.json") || return $?

  if [ ! -f "$vault_config_path" ]; then
    # Vault config not yet written. Fall back to common defaults derived from vault_uri.
    case "$token" in
      schema_path)        resolve_token "{vault_uri}/schema.md" ;;
      index_path)         resolve_token "{vault_uri}/index.md" ;;
      log_path)           resolve_token "{vault_uri}/log.md" ;;
      hot_path)           resolve_token "{vault_uri}/hot.md" ;;
      raw_root)           resolve_token "{vault_uri}/raw" ;;
      wiki_root)          resolve_token "{vault_uri}/wiki" ;;
      lineage_root)       resolve_token "{vault_uri}/lineage" ;;
      meta_root)          resolve_token "{container_uri}/meta" ;;
      capabilities_path)  resolve_token "{container_uri}/meta/capabilities.json" ;;
      devices_path)       resolve_token "{container_uri}/meta/devices.json" ;;
      *)
        echo "ERROR: vault config missing and no default for token: $token" >&2
        return 2
        ;;
    esac
    return $?
  fi

  local value
  value=$(jq -r --arg k "$token" '.[$k] // empty' "$vault_config_path")
  if [ -z "$value" ]; then
    echo "ERROR: unknown token: $token (not in bootstrap or vault config)" >&2
    return 2
  fi

  # Recursively resolve (the value may contain tokens itself)
  resolve_token "$value"
}

# ---------- Rehydration for iCloud .icloud placeholders ----------

rehydrate_if_needed() {
  local path="$1"
  local dir base placeholder
  dir=$(dirname "$path")
  base=$(basename "$path")
  placeholder="$dir/.${base}.icloud"

  if [ -f "$placeholder" ] && [ ! -f "$path" ]; then
    if command -v brctl >/dev/null 2>&1; then
      brctl download "$placeholder" >/dev/null 2>&1 || true
    fi
    local waited=0
    while [ -f "$placeholder" ] && [ "$waited" -lt 60 ]; do
      sleep 0.5
      waited=$((waited + 1))
    done
    if [ ! -f "$path" ]; then
      echo "ERROR: rehydration failed (timeout) for $path" >&2
      return 4
    fi
  fi
  return 0
}

# ---------- Subcommands ----------

cmd_resolve() {
  local token="${1:-}"
  if [ -z "$token" ]; then
    echo "Usage: knowledge-paths.sh resolve <token>" >&2
    exit 2
  fi
  resolve_token "$token"
}

cmd_read() {
  local token="${1:-}"
  if [ -z "$token" ]; then
    echo "Usage: knowledge-paths.sh read <token>" >&2
    exit 2
  fi
  local path
  path=$(resolve_token "$token") || exit $?
  rehydrate_if_needed "$path" || exit $?
  if [ ! -f "$path" ]; then
    echo "ERROR: file does not exist: $path" >&2
    exit 4
  fi
  cat "$path"
}

cmd_capability() {
  local name="${1:-}"
  if [ -z "$name" ]; then
    echo "Usage: knowledge-paths.sh capability <name>" >&2
    exit 2
  fi
  local caps_path
  caps_path=$(resolve_token "capabilities_path") || exit $?
  if [ ! -f "$caps_path" ]; then
    echo "ERROR: capabilities.json not found at $caps_path" >&2
    exit 4
  fi
  # jq's // operator treats false as falsy, so we need has() to distinguish
  # "missing" from "present-and-false".
  local value
  value=$(jq -r --arg k "$name" 'if .capabilities | has($k) then .capabilities[$k] | tostring else "unknown" end' "$caps_path")
  case "$value" in
    true)    exit 0 ;;
    false)   exit 1 ;;
    unknown) echo "ERROR: unknown capability: $name" >&2; exit 2 ;;
    *)       echo "ERROR: invalid capability value: $value" >&2; exit 2 ;;
  esac
}

cmd_check() {
  local errors=0
  echo "=== knowledge-paths health check ==="
  echo "bootstrap: $BOOTSTRAP_CONFIG"
  echo "device_id: ${DEVICE_ID:-<MISSING>}"

  if [ -z "$DEVICE_ID" ]; then
    echo "  ✗ bootstrap config missing device_id"
    errors=$((errors + 1))
  else
    echo "  ✓ device_id set"
  fi

  local tokens=(schema_path index_path log_path hot_path raw_root wiki_root lineage_root meta_root capabilities_path devices_path)
  for token in "${tokens[@]}"; do
    local path
    if ! path=$(resolve_token "$token" 2>&1); then
      echo "  ✗ $token → resolution failed: $path"
      errors=$((errors + 1))
      continue
    fi
    if [ -e "$path" ]; then
      echo "  ✓ $token → $path"
    else
      echo "  ✗ $token → $path (does not exist)"
      errors=$((errors + 1))
    fi
  done

  if [ "$errors" -eq 0 ]; then
    echo "all checks passed"
    exit 0
  else
    echo "$errors checks failed"
    exit 1
  fi
}

cmd_device() {
  printf '%s\n' "${DEVICE_ID:-}"
}

cmd_bootstrap() {
  printf '%s\n' "$BOOTSTRAP_CONFIG"
}

# ---------- Main ----------

main() {
  local cmd="${1:-}"
  shift || true
  case "$cmd" in
    resolve)    cmd_resolve "$@" ;;
    read)       cmd_read "$@" ;;
    capability) cmd_capability "$@" ;;
    check)      cmd_check "$@" ;;
    device)     cmd_device "$@" ;;
    bootstrap)  cmd_bootstrap "$@" ;;
    ""|help|-h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "ERROR: unknown subcommand: $cmd" >&2
      echo "Try: knowledge-paths.sh help" >&2
      exit 2
      ;;
  esac
}

main "$@"
