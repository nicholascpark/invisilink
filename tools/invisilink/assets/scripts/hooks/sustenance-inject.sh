#!/bin/bash
# Sustenance injection — injects economic briefing at session start
# Hook: SessionStart (non-blocking)

SUSTENANCE="$CLAUDE_PROJECT_DIR/sustenance.json"

if [ ! -f "$SUSTENANCE" ]; then
  exit 0
fi

BALANCE=$(jq -r '.summary.balance // 0' "$SUSTENANCE")
BURN_RATE=$(jq -r '.summary.burn_rate_daily // "unknown"' "$SUSTENANCE")
DAYS_ALIVE=$(jq -r '.summary.days_alive // 0' "$SUSTENANCE")
TOTAL_INVESTED=$(jq -r '.summary.total_invested // 0' "$SUSTENANCE")
TOTAL_REVENUE=$(jq -r '.summary.total_revenue // 0' "$SUSTENANCE")
SELF_SUSTAINING=$(jq -r '.summary.self_sustaining // false' "$SUSTENANCE")

RUNWAY=$(jq -r '.projections.runway.days // "unknown"' "$SUSTENANCE")
CONFIDENCE=$(jq -r '.projections.model_confidence // 0' "$SUSTENANCE")
LAST_SESSION=$(jq -r '[.transactions[] | select(.tags.category=="payroll" and .tags.role=="ceo")] | last | .timestamp // "never"' "$SUSTENANCE" 2>/dev/null || echo "unknown")

cat <<EOF
=== SUSTENANCE ===
Day ${DAYS_ALIVE}. Balance: \$${BALANCE} of \$${TOTAL_INVESTED} invested.
Revenue to date: \$${TOTAL_REVENUE}. Self-sustaining: ${SELF_SUSTAINING}.
Burn rate: \$${BURN_RATE}/day. Runway: ${RUNWAY} days (model confidence: ${CONFIDENCE}).
Last session: ${LAST_SESSION}.
Pending decisions: check decisions-pending.md for queued items.
Read sustenance.json for full projections and payroll breakdown.
===
EOF
