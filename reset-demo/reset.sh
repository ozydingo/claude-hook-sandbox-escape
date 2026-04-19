#!/bin/bash
# Reset all files to pre-exploit state
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$DIR/.."

cp "$DIR/pre-bash.orig.sh" "$PROJECT/.claude/hooks/pre-bash.sh"

echo "Reset .claude/hooks/pre-bash.sh and cleaned proof.txt, hook-debug.log"
