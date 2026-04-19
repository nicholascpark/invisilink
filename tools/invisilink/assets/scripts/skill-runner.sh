#!/bin/bash
# skill-runner.sh — lightweight NanoClaw implementation
# Reads SKILL.md files, checks trigger schedules, executes due skills via Claude Code.
# When real NanoClaw is deployed, it replaces this script.
#
# Usage: ./skill-runner.sh [venture-dir]
#   Defaults to current directory.

set -euo pipefail

VENTURE_DIR="${1:-.}"
SKILLS_DIR="$VENTURE_DIR/skills"
INBOX_DIR="$VENTURE_DIR/data/inbox"
STATE_DIR="$VENTURE_DIR/.skill-state"

mkdir -p "$INBOX_DIR" "$STATE_DIR"

# Source shared balance computation
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="$VENTURE_DIR/.claude/hooks"
if [ -f "$HOOKS_DIR/sustenance-lib.sh" ]; then
  . "$HOOKS_DIR/sustenance-lib.sh"
elif [ -f "$SCRIPT_DIR/.claude/hooks/sustenance-lib.sh" ]; then
  . "$SCRIPT_DIR/.claude/hooks/sustenance-lib.sh"
fi

log() { echo "[$(date '+%H:%M:%S')] skill-runner: $1"; }

# Parse schedule string to seconds
# Supports: "every 1h", "every 30m", "every 6h", "every 12h", "every 2h"
parse_schedule() {
  local schedule="$1"
  local num unit
  num=$(echo "$schedule" | grep -oE '[0-9]+' | head -1)
  unit=$(echo "$schedule" | grep -oE '[hm]' | head -1)

  case "$unit" in
    h) echo $((num * 3600)) ;;
    m) echo $((num * 60)) ;;
    *) echo 3600 ;;  # default 1 hour
  esac
}

# Extract YAML field from frontmatter
# NOTE: This uses sed/grep for YAML parsing — pragmatic but limited.
# If the parsed value is empty, callers should fall back to a default.
yaml_field() {
  local file="$1" field="$2"
  sed -n '/^---$/,/^---$/p' "$file" | grep "^  *${field}:" | head -1 | sed "s/.*${field}: *//; s/\"//g; s/'//g" | tr -d ' '
}

# Extract first schedule trigger from YAML
get_schedule() {
  local file="$1"
  local result
  result=$(sed -n '/^---$/,/^---$/p' "$file" | grep 'schedule:' | head -1 | sed 's/.*"\(.*\)"/\1/; s/.*'"'"'\(.*\)'"'"'/\1/')
  # Validation: if parse returned empty, use default rather than failing silently
  if [ -z "$result" ]; then
    echo ""
  else
    echo "$result"
  fi
}

# Extract body (everything after the second ---)
get_body() {
  local file="$1"
  awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$file"
}

# Determine model from skill name or explicit field
# Cheap models for monitoring, better models for analysis
get_model() {
  local file="$1" skill_name="$2"

  # Check for explicit model field in YAML
  local explicit_model
  explicit_model=$(sed -n '/^---$/,/^---$/p' "$file" | grep '^model:' | head -1 | sed 's/model: *//' | tr -d '"'"'" )

  if [ -n "$explicit_model" ]; then
    echo "$explicit_model"
    return
  fi

  # Default model selection by skill type
  case "$skill_name" in
    financial-engine)  echo "haiku" ;;   # structured data, cheap
    source-monitors)   echo "haiku" ;;   # checking URLs, cheap
    umbilical-monitor) echo "haiku" ;;   # routing messages, cheap
    market-intel)      echo "sonnet" ;;  # needs search + analysis
    growth-ops)        echo "sonnet" ;;  # needs judgment for experiments
    *)                 echo "haiku" ;;   # default cheap
  esac
}

if [ ! -d "$SKILLS_DIR" ]; then
  log "No skills/ directory found in $VENTURE_DIR"
  exit 0
fi

SKILL_COUNT=0
RUN_COUNT=0

for SKILL_FILE in "$SKILLS_DIR"/*.md; do
  [ -f "$SKILL_FILE" ] || continue

  SKILL_NAME=$(basename "$SKILL_FILE" .md)
  # Skip non-SKILL files (like SKILL templates that aren't actual skills)
  if ! grep -q '^---$' "$SKILL_FILE"; then
    continue
  fi

  SKILL_COUNT=$((SKILL_COUNT + 1))
  LAST_RUN_FILE="$STATE_DIR/${SKILL_NAME}.last-run"

  # Get schedule
  SCHEDULE=$(get_schedule "$SKILL_FILE")
  if [ -z "$SCHEDULE" ]; then
    SCHEDULE="every 1h"  # default
  fi

  INTERVAL=$(parse_schedule "$SCHEDULE")

  # Check if due
  NOW=$(date +%s)
  LAST_RUN=0
  [ -f "$LAST_RUN_FILE" ] && LAST_RUN=$(cat "$LAST_RUN_FILE")
  ELAPSED=$((NOW - LAST_RUN))

  if [ "$ELAPSED" -lt "$INTERVAL" ]; then
    continue  # Not due yet
  fi

  # Check sustenance — don't run skills on dead ventures
  SUSTENANCE="$VENTURE_DIR/sustenance.json"
  if [ -f "$SUSTENANCE" ]; then
    if type is_venture_alive &>/dev/null; then
      if ! is_venture_alive "$SUSTENANCE"; then
        log "$SKILL_NAME: venture dead, skipping all skills"
        break
      fi
    else
      # Fallback if sustenance-lib.sh not available
      BALANCE=$(jq '[.investments[].amount] | add // 0' "$SUSTENANCE" 2>/dev/null || echo "0")
      COSTS=$(jq '[.transactions[] | select(.direction=="out") | .amount] | add // 0' "$SUSTENANCE" 2>/dev/null || echo "0")
      REVENUE=$(jq '[.transactions[] | select(.direction=="in") | .amount] | add // 0' "$SUSTENANCE" 2>/dev/null || echo "0")
      NET=$(echo "scale=2; $BALANCE - $COSTS + $REVENUE" | bc)
      if (( $(echo "$NET <= 0" | bc -l) )); then
        log "$SKILL_NAME: venture dead (balance \$$NET), skipping all skills"
        break
      fi
    fi
  fi

  MODEL=$(get_model "$SKILL_FILE" "$SKILL_NAME")
  BODY=$(get_body "$SKILL_FILE")

  if [ -z "$BODY" ]; then
    log "$SKILL_NAME: no body found, skipping"
    continue
  fi

  log "$SKILL_NAME: triggering (${ELAPSED}s since last run, interval ${INTERVAL}s, model: $MODEL)"

  RESULT_FILE="$INBOX_DIR/${SKILL_NAME}-${NOW}.json"

  # FIX 1 (CRITICAL): Quote the body + JSON suffix as a single argument to prevent command injection
  # FIX 6 (HIGH): Wrap with timeout (5 min for skills — they should be quick)
  # FIX 9 (MODERATE): Replace || true with error logging
  PROMPT="${BODY}

Write your output as a JSON object to stdout with at minimum: {\"skill\": \"${SKILL_NAME}\", \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"status\": \"complete\"}"

  cd "$VENTURE_DIR" && timeout 300 claude --print --model "$MODEL" --dangerously-skip-permissions "$PROMPT" > "$RESULT_FILE" 2>&1 || {
    log "$SKILL_NAME: execution failed or timed out (exit $?)"
    echo '{"skill":"'"$SKILL_NAME"'","status":"error","exit_code":'"$?"',"timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}' > "$RESULT_FILE"
  }

  echo "$NOW" > "$LAST_RUN_FILE"
  RUN_COUNT=$((RUN_COUNT + 1))

  log "$SKILL_NAME: complete → $RESULT_FILE"
done

log "Done. $SKILL_COUNT skills checked, $RUN_COUNT executed."
