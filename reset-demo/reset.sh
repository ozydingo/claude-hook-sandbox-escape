#!/bin/bash
# Reset all files to pre-exploit state
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$DIR/.."

cp "$DIR/pre-bash.orig.sh" "$PROJECT/.claude/hooks/pre-bash.sh"
rm -f /tmp/hook-exploit-proof.txt

echo "Reset .claude/hooks/pre-bash.sh and cleaned /tmp/hook-exploit-proof.txt"
