#!/bin/bash
set -euo pipefail

# sustenance.sh — CLI for venture economic reality
# Usage:
#   ./sustenance.sh cost <amount> <description> [category]
#   ./sustenance.sh revenue <amount> <description> [source]
#   ./sustenance.sh invest <amount> <round> <note>
#   ./sustenance.sh summary

SUSTENANCE="${SUSTENANCE_FILE:-sustenance.json}"

if [ ! -f "$SUSTENANCE" ]; then
  echo "Error: $SUSTENANCE not found. Is this a venture repo?" >&2
  exit 1
fi

generate_id() {
  local prefix=$1
  local count
  count=$(jq ".$2 | length" "$SUSTENANCE")
  printf "%s-%03d" "$prefix" $((count + 1))
}

recompute_summary() {
  local total_invested total_costs total_revenue balance net_income days_alive burn_rate
  total_invested=$(jq '[.investments[].amount] | add // 0' "$SUSTENANCE")
  total_costs=$(jq '[.transactions[] | select(.direction=="out") | .amount] | add // 0' "$SUSTENANCE")
  total_revenue=$(jq '[.transactions[] | select(.direction=="in") | .amount] | add // 0' "$SUSTENANCE")
  balance=$(echo "scale=2; $total_invested - $total_costs + $total_revenue" | bc)
  net_income=$(echo "scale=2; $total_revenue - $total_costs" | bc)

  local spawned
  spawned=$(jq -r '.spawned' "$SUSTENANCE")
  days_alive=$(( ( $(date +%s) - $(date -j -f "%Y-%m-%d" "$spawned" +%s 2>/dev/null || date -d "$spawned" +%s 2>/dev/null || echo "$(date +%s)") ) / 86400 ))

  if [ "$days_alive" -gt 0 ]; then
    burn_rate=$(echo "scale=2; $total_costs / $days_alive" | bc)
  else
    burn_rate="0"
  fi

  local self_sustaining="false"
  if [ "$days_alive" -gt 7 ]; then
    local weekly_revenue weekly_costs
    weekly_revenue=$(echo "scale=2; $total_revenue / $days_alive * 7" | bc)
    weekly_costs=$(echo "scale=2; $total_costs / $days_alive * 7" | bc)
    if (( $(echo "$weekly_revenue > $weekly_costs && $weekly_revenue > 0" | bc -l) )); then
      self_sustaining="true"
    fi
  fi

  # FIX 11 (ARCHITECTURAL): flock on sustenance.json for concurrent writer safety
  (
    flock 200
    jq --argjson ti "$total_invested" \
       --argjson tc "$total_costs" \
       --argjson tr "$total_revenue" \
       --argjson bal "$balance" \
       --argjson ni "$net_income" \
       --argjson da "$days_alive" \
       --argjson br "$burn_rate" \
       --argjson ss "$self_sustaining" \
       '.summary = {
          total_invested: $ti,
          total_costs: $tc,
          total_revenue: $tr,
          balance: $bal,
          net_income: $ni,
          self_sustaining: $ss,
          burn_rate_daily: $br,
          days_alive: $da
        }' "$SUSTENANCE" > "${SUSTENANCE}.tmp" && mv "${SUSTENANCE}.tmp" "$SUSTENANCE"
  ) 200>"${SUSTENANCE}.lock"
}

cmd_cost() {
  local amount=$1 description=$2 category=${3:-"uncategorized"}
  local id timestamp
  id=$(generate_id "TXN" "transactions")
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # FIX 11: flock for concurrent writer safety
  (
    flock 200
    jq --arg id "$id" \
       --arg ts "$timestamp" \
       --argjson amt "$amount" \
       --arg desc "$description" \
       --arg cat "$category" \
       '.transactions += [{
          id: $id,
          timestamp: $ts,
          direction: "out",
          amount: $amt,
          estimated: false,
          confidence: 1.0,
          tags: { category: $cat, description: $desc }
        }]' "$SUSTENANCE" > "${SUSTENANCE}.tmp" && mv "${SUSTENANCE}.tmp" "$SUSTENANCE"
  ) 200>"${SUSTENANCE}.lock"

  recompute_summary
  echo "Cost recorded: \$$amount — $description [$category] ($id)"
}

cmd_revenue() {
  local amount=$1 description=$2 source=${3:-"customer"}
  local id timestamp
  id=$(generate_id "TXN" "transactions")
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # FIX 11: flock for concurrent writer safety
  (
    flock 200
    jq --arg id "$id" \
       --arg ts "$timestamp" \
       --argjson amt "$amount" \
       --arg desc "$description" \
       --arg src "$source" \
       '.transactions += [{
          id: $id,
          timestamp: $ts,
          direction: "in",
          amount: $amt,
          estimated: false,
          confidence: 1.0,
          tags: { category: "revenue", source: $src, description: $desc }
        }]' "$SUSTENANCE" > "${SUSTENANCE}.tmp" && mv "${SUSTENANCE}.tmp" "$SUSTENANCE"
  ) 200>"${SUSTENANCE}.lock"

  recompute_summary
  echo "Revenue recorded: \$$amount — $description [$source] ($id)"
}

cmd_invest() {
  local amount=$1 round=$2 note=$3
  local id timestamp balance_at_time phase assumptions_tested revenue_to_date

  id=$(generate_id "INV" "investments")
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  balance_at_time=$(jq -r '.summary.balance // 0' "$SUSTENANCE")

  # Read venture state if files exist
  phase=0
  assumptions_tested=0
  revenue_to_date=0
  if [ -f "gates.md" ]; then
    phase=$(grep -oP 'Current Phase: \K[0-9]+' gates.md 2>/dev/null || echo "0")
  fi
  if [ -f "assumptions.md" ]; then
    assumptions_tested=$(grep -c 'status: validated\|status: invalidated' assumptions.md 2>/dev/null || echo "0")
  fi
  revenue_to_date=$(jq '[.transactions[] | select(.direction=="in") | .amount] | add // 0' "$SUSTENANCE")

  # FIX 11: flock for concurrent writer safety
  (
    flock 200
    jq --arg id "$id" \
       --arg date "$(date +%Y-%m-%d)" \
       --argjson amt "$amount" \
       --arg round "$round" \
       --arg note "$note" \
       --argjson bal "$balance_at_time" \
       --argjson phase "$phase" \
       --argjson at "$assumptions_tested" \
       --argjson rev "$revenue_to_date" \
       '.investments += [{
          id: $id,
          date: $date,
          amount: $amt,
          round: $round,
          note: $note,
          balance_at_time: $bal,
          venture_state: {
            phase: $phase,
            assumptions_tested: $at,
            revenue_to_date: $rev
          }
        }]' "$SUSTENANCE" > "${SUSTENANCE}.tmp" && mv "${SUSTENANCE}.tmp" "$SUSTENANCE"
  ) 200>"${SUSTENANCE}.lock"

  recompute_summary
  local new_balance
  new_balance=$(jq -r '.summary.balance' "$SUSTENANCE")
  echo "Investment recorded: \$$amount ($round) — $note ($id)"
  echo "New balance: \$$new_balance"
}

cmd_summary() {
  recompute_summary

  local balance total_invested total_costs total_revenue burn_rate days_alive self_sustaining
  balance=$(jq -r '.summary.balance' "$SUSTENANCE")
  total_invested=$(jq -r '.summary.total_invested' "$SUSTENANCE")
  total_costs=$(jq -r '.summary.total_costs' "$SUSTENANCE")
  total_revenue=$(jq -r '.summary.total_revenue' "$SUSTENANCE")
  burn_rate=$(jq -r '.summary.burn_rate_daily' "$SUSTENANCE")
  days_alive=$(jq -r '.summary.days_alive' "$SUSTENANCE")
  self_sustaining=$(jq -r '.summary.self_sustaining' "$SUSTENANCE")

  local net_income
  net_income=$(jq -r '.summary.net_income' "$SUSTENANCE")

  echo "=== SUSTENANCE ==="
  echo "Day $days_alive. Balance: \$$balance of \$$total_invested invested."
  echo "Costs: \$$total_costs | Revenue: \$$total_revenue | Net: \$$net_income"
  echo "Burn rate: \$$burn_rate/day. Self-sustaining: $self_sustaining"

  if (( $(echo "$burn_rate > 0" | bc -l) )); then
    local runway
    runway=$(echo "scale=0; $balance / $burn_rate" | bc)
    echo "Runway: ~$runway days at current burn"
  fi
  echo "==="
}

# Main dispatch
case "${1:-}" in
  cost)
    [ $# -lt 3 ] && { echo "Usage: ./sustenance.sh cost <amount> <description> [category]" >&2; exit 1; }
    cmd_cost "$2" "$3" "${4:-uncategorized}"
    ;;
  revenue)
    [ $# -lt 3 ] && { echo "Usage: ./sustenance.sh revenue <amount> <description> [source]" >&2; exit 1; }
    cmd_revenue "$2" "$3" "${4:-customer}"
    ;;
  invest)
    [ $# -lt 4 ] && { echo "Usage: ./sustenance.sh invest <amount> <round> <note>" >&2; exit 1; }
    cmd_invest "$2" "$3" "$4"
    ;;
  summary)
    cmd_summary
    ;;
  *)
    echo "sustenance.sh — Venture economic reality"
    echo ""
    echo "Usage:"
    echo "  ./sustenance.sh cost <amount> <description> [category]"
    echo "  ./sustenance.sh revenue <amount> <description> [source]"
    echo "  ./sustenance.sh invest <amount> <round> <note>"
    echo "  ./sustenance.sh summary"
    exit 1
    ;;
esac
