#!/bin/bash
# Cost capture — estimates session token cost and writes to data/inbox
# Hook: Stop

INBOX="$CLAUDE_PROJECT_DIR/data/inbox"
mkdir -p "$INBOX"

SESSION_ID=$(date +%s)-$$
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

INPUT=$(cat)
TOKENS=$(echo "$INPUT" | jq -r '.context_usage.tokens // 50000' 2>/dev/null || echo "50000")

# FIX 10 (MODERATE): Configurable token cost rate via env var.
# The financial engine's learning model will calibrate this over time.
# Update TOKEN_COST_RATE when API pricing changes.
RATE="${TOKEN_COST_RATE:-0.000008}"
COST=$(echo "scale=2; $TOKENS * $RATE" | bc)

cat > "$INBOX/session-${SESSION_ID}.json" <<SESSEOF
{
  "type": "session-cost",
  "session_id": "${SESSION_ID}",
  "timestamp": "${TIMESTAMP}",
  "estimated_tokens": ${TOKENS},
  "estimated_cost_usd": ${COST},
  "auto": true,
  "confidence": 0.5
}
SESSEOF
