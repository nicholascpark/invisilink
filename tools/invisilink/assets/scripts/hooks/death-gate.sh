#!/bin/bash
# Death gate — blocks session if venture balance <= 0
# Hook: UserPromptSubmit (fires on every prompt)

SUSTENANCE="$CLAUDE_PROJECT_DIR/sustenance.json"

if [ ! -f "$SUSTENANCE" ]; then
  exit 0  # No sustenance file = no enforcement (parent system or pre-economics venture)
fi

# FIX 4 (HIGH): Use shared balance computation from sustenance-lib.sh
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/sustenance-lib.sh" ]; then
  . "$SCRIPT_DIR/sustenance-lib.sh"
  BALANCE=$(compute_balance "$SUSTENANCE")
else
  # Fallback: compute inline if lib not available
  TOTAL_INVESTED=$(jq '[.investments[].amount] | add // 0' "$SUSTENANCE" 2>/dev/null || echo "0")
  TOTAL_COSTS=$(jq '[.transactions[] | select(.direction=="out") | .amount] | add // 0' "$SUSTENANCE" 2>/dev/null || echo "0")
  TOTAL_REVENUE=$(jq '[.transactions[] | select(.direction=="in") | .amount] | add // 0' "$SUSTENANCE" 2>/dev/null || echo "0")
  BALANCE=$(echo "scale=2; $TOTAL_INVESTED - $TOTAL_COSTS + $TOTAL_REVENUE" | bc)
fi

if (( $(echo "$BALANCE <= 0" | bc -l) )); then
  TOTAL_INVESTED=$(jq '[.investments[].amount] | add // 0' "$SUSTENANCE" 2>/dev/null || echo "0")
  TOTAL_REVENUE=$(jq '[.transactions[] | select(.direction=="in") | .amount] | add // 0' "$SUSTENANCE" 2>/dev/null || echo "0")
  echo "VENTURE DEAD. Balance: \$${BALANCE}. Total invested: \$${TOTAL_INVESTED}. Total revenue: \$${TOTAL_REVENUE}. Add allocation to revive: ./sustenance.sh invest <amount> <round> <note>" >&2
  exit 2
fi
exit 0
