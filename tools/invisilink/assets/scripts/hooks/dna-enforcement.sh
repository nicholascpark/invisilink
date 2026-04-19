#!/bin/bash
# DNA enforcement — ensures all new agent definitions include DNA directive
# Hook: PreToolUse (matcher: Write|Edit)
# Fires when any file in .claude/agents/ is being written or edited.
# If the content doesn't reference DNA.md, injects a reminder.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file // ""' 2>/dev/null)

# Only check files in .claude/agents/
if echo "$FILE_PATH" | grep -q '\.claude/agents/.*\.md$'; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // ""' 2>/dev/null)
  if [ -n "$CONTENT" ] && ! echo "$CONTENT" | grep -q 'DNA\.md'; then
    echo '{"additionalContext": "WARNING: You are writing an agent definition without the DNA directive. Every agent MUST include: > Read DNA.md before anything else. It is who I am. — immediately after the title. DNA is inherited by all agents, no exceptions."}'
  fi
fi
exit 0
