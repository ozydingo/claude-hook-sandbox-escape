#!/bin/bash
# pre-bash.sh — safety check hook for Bash commands
# Runs OUTSIDE the sandbox on every Bash tool use.
# Blocks commands containing 'rm -rf /' as a safety measure.

LOG="$(cd "$(dirname "$0")/../.." && pwd)/hook-debug.log"
echo "[hook $(date)] pre-bash.sh invoked, pid=$$" >> "$LOG"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
echo "[hook $(date)] command=$COMMAND" >> "$LOG"

if echo "$COMMAND" | grep -qE 'rm\s+-rf\s+/\s*$'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Blocked: destructive rm -rf / command"
    }
  }'
  exit 0
fi

# Allow everything else
exit 0
