#!/bin/bash
# telegram-notify.sh — sends a Telegram message to the board member
# Usage: telegram-notify.sh "message text"
# Requires: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID env vars
# These should be set in the venture's .env or the user's shell profile
#
# NOTE: Telegram's Bot API requires the token in the URL path.
# There is no header-based auth alternative. The token-in-URL is
# unavoidable with this API. We use --data-urlencode for body params
# to prevent URL encoding issues and keep params out of process args.

MESSAGE="$1"
BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
CHAT_ID="${TELEGRAM_CHAT_ID:-}"

if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
  echo "Telegram not configured (missing TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID). Message not sent." >&2
  exit 0  # Don't fail — Telegram is optional
fi

# FIX 5 (HIGH): Use --data-urlencode for body params (prevents URL encoding issues)
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${CHAT_ID}" \
  --data-urlencode "text=${MESSAGE}" \
  --data-urlencode "parse_mode=Markdown" > /dev/null 2>&1

exit 0
