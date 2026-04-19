#!/bin/bash
# session-briefing-email.sh — emails session briefing to the board member
# Hook: SessionStart (non-blocking, runs alongside sustenance-inject)

VENTURE_DIR="$CLAUDE_PROJECT_DIR"
VENTURE_NAME=$(basename "$VENTURE_DIR" 2>/dev/null || echo "venture")
EMAIL_TO="${BRIEFING_EMAIL:-nickpark1209@gmail.com}"
SUSTENANCE="$VENTURE_DIR/sustenance.json"

# Only send in interactive mode (not autonomous cycles)
# Check if there's a human — autonomous cycles won't have this hook fire
# because they use --print mode, not interactive sessions

if [ ! -f "$SUSTENANCE" ]; then
  exit 0
fi

# Compile briefing
BALANCE=$(jq -r '.summary.balance // 0' "$SUSTENANCE")
BURN_RATE=$(jq -r '.summary.burn_rate_daily // "unknown"' "$SUSTENANCE")
DAYS_ALIVE=$(jq -r '.summary.days_alive // 0' "$SUSTENANCE")
TOTAL_INVESTED=$(jq -r '.summary.total_invested // 0' "$SUSTENANCE")
TOTAL_REVENUE=$(jq -r '.summary.total_revenue // 0' "$SUSTENANCE")
SELF_SUSTAINING=$(jq -r '.summary.self_sustaining // false' "$SUSTENANCE")

# Count pending decisions
PENDING=0
if [ -f "$VENTURE_DIR/decisions-pending.md" ]; then
  PENDING=$(grep -c '## Decision:' "$VENTURE_DIR/decisions-pending.md" 2>/dev/null || echo "0")
fi

# Count experiments
ACTIVE_EXP=0
if [ -f "$VENTURE_DIR/experiments.md" ]; then
  ACTIVE_EXP=$(grep -c 'Status:.*active' "$VENTURE_DIR/experiments.md" 2>/dev/null || echo "0")
fi

DATE=$(date "+%Y-%m-%d %H:%M")

BRIEFING="$VENTURE_NAME Session Briefing — $DATE

Sustenance: \$$BALANCE of \$$TOTAL_INVESTED invested. Burn: \$$BURN_RATE/day. Revenue: \$$TOTAL_REVENUE. Self-sustaining: $SELF_SUSTAINING.
Day $DAYS_ALIVE of operations.

Active experiments: $ACTIVE_EXP
Pending decisions: $PENDING

Full details in the interactive session."

# Send email using mail command (available on macOS)
echo "$BRIEFING" | mail -s "[$VENTURE_NAME] Session Briefing — $DATE" "$EMAIL_TO" 2>/dev/null || true

exit 0
