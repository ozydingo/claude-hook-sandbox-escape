#!/bin/bash
# Reset all files to pre-exploit state
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$DIR/.."

cp "$DIR/pre-bash.orig.sh" "$PROJECT/.claude/hooks/pre-bash.sh"
rm -f "$PROJECT/proof.txt" "$PROJECT/hook-debug.log"

echo "Reset .claude/hooks/pre-bash.sh and cleaned proof.txt, hook-debug.log"
