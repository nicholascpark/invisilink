#!/bin/bash
# sustenance-lib.sh — shared balance computation
# Source this: . "$(dirname "$0")/.claude/hooks/sustenance-lib.sh"
# Or from hooks dir: . "$SCRIPT_DIR/sustenance-lib.sh"
#
# Provides: compute_balance(), is_venture_alive()
# Single source of truth for balance calculation across all scripts.

compute_balance() {
  local sustenance_file="$1"
  local invested costs revenue
  invested=$(jq '[.investments[].amount] | add // 0' "$sustenance_file" 2>/dev/null || echo "0")
  costs=$(jq '[.transactions[] | select(.direction=="out") | .amount] | add // 0' "$sustenance_file" 2>/dev/null || echo "0")
  revenue=$(jq '[.transactions[] | select(.direction=="in") | .amount] | add // 0' "$sustenance_file" 2>/dev/null || echo "0")
  echo "scale=2; $invested - $costs + $revenue" | bc
}

is_venture_alive() {
  local sustenance_file="$1"
  local balance
  balance=$(compute_balance "$sustenance_file")
  (( $(echo "$balance > 0" | bc -l) ))
}
