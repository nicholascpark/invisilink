#!/bin/bash
# healthcheck.sh — verify a venture is correctly configured
# Usage: ./healthcheck.sh [venture-dir]

VENTURE_DIR="${1:-.}"
PASS=0
FAIL=0

check() {
  local desc="$1" result="$2"
  if [ "$result" = "true" ]; then
    echo "  ✓ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Healthcheck: $(basename $VENTURE_DIR) ==="

# Core files
check "DNA.md exists" "$([ -f $VENTURE_DIR/DNA.md ] && echo true || echo false)"
check "DNA.md is first-person" "$(! grep -q '\byou\b\|\byour\b' $VENTURE_DIR/DNA.md 2>/dev/null && echo true || echo false)"
check "sustenance.json exists" "$([ -f $VENTURE_DIR/sustenance.json ] && echo true || echo false)"
check "sustenance.sh exists and executable" "$([ -x $VENTURE_DIR/sustenance.sh ] && echo true || echo false)"
check "CLAUDE.md exists" "$([ -f $VENTURE_DIR/CLAUDE.md ] && echo true || echo false)"
check "CLAUDE.md references DNA.md" "$(grep -q 'DNA.md' $VENTURE_DIR/CLAUDE.md 2>/dev/null && echo true || echo false)"
check "decisions-pending.md exists" "$([ -f $VENTURE_DIR/decisions-pending.md ] && echo true || echo false)"
check "triggers.json exists" "$([ -f $VENTURE_DIR/triggers.json ] && echo true || echo false)"
check "experiments.md exists" "$([ -f $VENTURE_DIR/experiments.md ] && echo true || echo false)"
check "program.md exists" "$([ -f $VENTURE_DIR/program.md ] && echo true || echo false)"

# Hooks
check "death-gate.sh exists and executable" "$([ -x $VENTURE_DIR/.claude/hooks/death-gate.sh ] && echo true || echo false)"
check "sustenance-inject.sh exists" "$([ -x $VENTURE_DIR/.claude/hooks/sustenance-inject.sh ] && echo true || echo false)"
check "cost-capture.sh exists" "$([ -x $VENTURE_DIR/.claude/hooks/cost-capture.sh ] && echo true || echo false)"
check "dna-enforcement.sh exists" "$([ -x $VENTURE_DIR/.claude/hooks/dna-enforcement.sh ] && echo true || echo false)"
check "irrevocable-gate.sh exists" "$([ -x $VENTURE_DIR/.claude/hooks/irrevocable-gate.sh ] && echo true || echo false)"
check "telegram-notify.sh exists" "$([ -x $VENTURE_DIR/.claude/hooks/telegram-notify.sh ] && echo true || echo false)"
check "session-briefing-email.sh exists" "$([ -x $VENTURE_DIR/.claude/hooks/session-briefing-email.sh ] && echo true || echo false)"

# Settings
check "settings.json has hooks" "$([ -f $VENTURE_DIR/.claude/settings.json ] && jq '.hooks' $VENTURE_DIR/.claude/settings.json >/dev/null 2>&1 && echo true || echo false)"

# Skills
check "skills/ directory exists" "$([ -d $VENTURE_DIR/skills ] && echo true || echo false)"
SKILL_COUNT=$(ls $VENTURE_DIR/skills/*.md 2>/dev/null | wc -l | tr -d ' ')
check "skills/ has definitions ($SKILL_COUNT found)" "$([ $SKILL_COUNT -ge 1 ] && echo true || echo false)"

# Data directories
check "data/inbox exists" "$([ -d $VENTURE_DIR/data/inbox ] && echo true || echo false)"
check "data/inbox/processed exists" "$([ -d $VENTURE_DIR/data/inbox/processed ] && echo true || echo false)"
check "data/outbox exists" "$([ -d $VENTURE_DIR/data/outbox ] && echo true || echo false)"

# Agent DNA directives
AGENTS_WITH_DNA=$(grep -rl 'DNA.md' $VENTURE_DIR/.claude/agents/ 2>/dev/null | wc -l | tr -d ' ')
TOTAL_AGENTS=$(find $VENTURE_DIR/.claude/agents -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
check "All agents reference DNA.md ($AGENTS_WITH_DNA/$TOTAL_AGENTS)" "$([ $AGENTS_WITH_DNA -eq $TOTAL_AGENTS ] && echo true || echo false)"

# Sustenance functional test
check "sustenance.sh runs without error" "$(cd $VENTURE_DIR && SUSTENANCE_FILE=sustenance.json ./sustenance.sh summary >/dev/null 2>&1 && echo true || echo false)"

# Death gate functional test
BALANCE=$(jq '[.investments[].amount] | add // 0' $VENTURE_DIR/sustenance.json 2>/dev/null || echo "0")
if [ "$BALANCE" = "0" ]; then
  CLAUDE_PROJECT_DIR=$VENTURE_DIR bash $VENTURE_DIR/.claude/hooks/death-gate.sh 2>/dev/null
  GATE_EXIT=$?
  check "Death gate blocks unfunded venture (exit=$GATE_EXIT)" "$([ $GATE_EXIT -eq 2 ] && echo true || echo false)"
else
  check "Death gate passes funded venture" "$(CLAUDE_PROJECT_DIR=$VENTURE_DIR bash $VENTURE_DIR/.claude/hooks/death-gate.sh 2>/dev/null && echo true || echo false)"
fi

# Skill runner test
check "skill-runner.sh exists and executable" "$([ -x $VENTURE_DIR/skill-runner.sh ] || [ -x $(dirname $0)/skill-runner.sh ] && echo true || echo false)"

# Healthcheck self-test
check "healthcheck.sh exists and executable" "$([ -x $VENTURE_DIR/healthcheck.sh ] || [ -x $(dirname $0)/healthcheck.sh ] && echo true || echo false)"

echo ""
echo "--- Runtime Tests ---"

# 1. Claude Code headless execution test
CLAUDE_TEST=$(cd "$VENTURE_DIR" && claude --print --model haiku --dangerously-skip-permissions "Respond with exactly: HEARTBEAT_OK" 2>/dev/null | grep -c "HEARTBEAT_OK" || echo "0")
check "Claude Code headless execution" "$([ "$CLAUDE_TEST" -gt 0 ] && echo true || echo false)"

# 2. Telegram connectivity test
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
  TG_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" -d "chat_id=${TELEGRAM_CHAT_ID}" -d "text=🏥 Healthcheck: $(basename $VENTURE_DIR) — testing Telegram connectivity" 2>/dev/null)
  check "Telegram connectivity (HTTP $TG_RESPONSE)" "$([ "$TG_RESPONSE" = "200" ] && echo true || echo false)"
else
  echo "  ⊘ Telegram not configured (TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID not set) — skipped"
fi

# 3. Skill-runner execution test
if [ -x "$VENTURE_DIR/skill-runner.sh" ]; then
  RUNNER_OUTPUT=$(cd "$VENTURE_DIR" && ./skill-runner.sh "$VENTURE_DIR" 2>&1)
  RUNNER_EXIT=$?
  check "skill-runner.sh executes without error (exit $RUNNER_EXIT)" "$([ $RUNNER_EXIT -eq 0 ] && echo true || echo false)"
elif [ -x "$(dirname $0)/skill-runner.sh" ]; then
  RUNNER_OUTPUT=$("$(dirname $0)/skill-runner.sh" "$VENTURE_DIR" 2>&1)
  RUNNER_EXIT=$?
  check "skill-runner.sh executes without error (exit $RUNNER_EXIT)" "$([ $RUNNER_EXIT -eq 0 ] && echo true || echo false)"
else
  check "skill-runner.sh found" "false"
fi

# 4. Email delivery test
if [ -n "${BRIEFING_EMAIL:-}" ]; then
  echo "Healthcheck test — $(basename $VENTURE_DIR) — $(date)" | mail -s "[$(basename $VENTURE_DIR)] Healthcheck Test" "$BRIEFING_EMAIL" 2>/dev/null
  MAIL_EXIT=$?
  check "Email delivery (exit $MAIL_EXIT)" "$([ $MAIL_EXIT -eq 0 ] && echo true || echo false)"
else
  echo "  ⊘ Email not configured (BRIEFING_EMAIL not set) — skipped"
fi

# 5. Heartbeat daemon test
# FIX 3: Check per-venture PID file (not shared /tmp/venture-heartbeat.pid)
VENTURE_NAME=$(basename "$VENTURE_DIR")
HB_PID_FILE="/tmp/venture-heartbeat-${VENTURE_NAME}.pid"
if [ -f "$HB_PID_FILE" ]; then
  HB_PID=$(cat "$HB_PID_FILE")
  if kill -0 "$HB_PID" 2>/dev/null; then
    check "Heartbeat daemon running (PID $HB_PID)" "true"
  else
    check "Heartbeat daemon running" "false"
    echo "    → Start with: ./venture-heartbeat.sh $VENTURE_DIR &"
  fi
else
  check "Heartbeat daemon running" "false"
  echo "    → Start with: ./venture-heartbeat.sh $VENTURE_DIR &"
  echo "    → Kill with: kill \$(cat $HB_PID_FILE)"
fi

# 6. fswatch availability test
check "fswatch installed (event-driven mode)" "$(command -v fswatch >/dev/null 2>&1 && echo true || echo false)"
if ! command -v fswatch >/dev/null 2>&1; then
  echo "    → Install with: brew install fswatch (falls back to polling without it)"
fi

# 7. Event trigger test
TEST_EVENT="$VENTURE_DIR/data/inbox/healthcheck-test-$(date +%s).json"
echo '{"type":"healthcheck","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > "$TEST_EVENT"
check "Event file write to data/inbox" "$([ -f "$TEST_EVENT" ] && echo true || echo false)"
rm -f "$TEST_EVENT"  # Clean up test event

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -eq 0 ]; then
  echo "Venture is fully operational."
else
  echo "Venture has $FAIL issue(s). Fix the failures above."
fi
exit $FAIL
