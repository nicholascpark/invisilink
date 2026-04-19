#!/bin/bash
# irrevocable-gate.sh — blocks irrevocable actions, notifies via Telegram
# Hook: PreToolUse (matcher: Bash)
# Irrevocable actions: send-email, make-call, make-payment, stripe charge,
# any curl to payment/email/SMS APIs

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Check for irrevocable action patterns
IRREVOCABLE=false
REASON=""

# Email sending
if echo "$COMMAND" | grep -qiE 'send.*email|sendgrid|resend.*send|mailgun|ses.*send|smtp'; then
  IRREVOCABLE=true
  REASON="Email send detected"
fi

# Payment processing
if echo "$COMMAND" | grep -qiE 'stripe.*charge|stripe.*payment|stripe.*invoice|payment.*create|charge.*create'; then
  IRREVOCABLE=true
  REASON="Payment processing detected"
fi

# Phone calls / SMS
if echo "$COMMAND" | grep -qiE 'twilio.*call|twilio.*message|make.*call|send.*sms|vapi|bland\.ai'; then
  IRREVOCABLE=true
  REASON="Phone call or SMS detected"
fi

if [ "$IRREVOCABLE" = true ]; then
  # Try to notify via Telegram
  VENTURE_NAME=$(basename "$CLAUDE_PROJECT_DIR" 2>/dev/null || echo "unknown")
  SCRIPT_DIR="$(dirname "$0")"
  if [ -x "$SCRIPT_DIR/telegram-notify.sh" ]; then
    "$SCRIPT_DIR/telegram-notify.sh" "⚠️ *${VENTURE_NAME}* wants to execute an irrevocable action:

*Reason:* ${REASON}
*Command:* \`${COMMAND:0:200}\`

Reply in the next session to approve or reject."
  fi

  echo "BLOCKED: ${REASON}. Irrevocable actions require human approval. Queue this in decisions-pending.md with full context and wait for the next interactive session." >&2
  exit 2
fi

exit 0
