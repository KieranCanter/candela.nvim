#!/usr/bin/env bash
# Run from repo root: ./scripts/run-unit-tests.sh [-o path]

OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output) OUTPUT="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

PLENARY=${PLENARY_PATH:-$(find ~/.local/share/nvim -type d -name "plenary.nvim" 2>/dev/null | head -1)}

if [ -z "$PLENARY" ]; then
    echo "plenary.nvim not found. Set PLENARY_PATH or install it."
    exit 1
fi

RESULTS=$(nvim --headless \
    --noplugin \
    -u NONE \
    -c "set rtp+=." \
    -c "set rtp+=$PLENARY" \
    -c "runtime plugin/plenary.vim" \
    -c "lua require('plenary.test_harness').test_directory('tests', { minimal_init = 'tests/minimal_init.lua', sequential = true })" 2>&1)

echo "$RESULTS"

# Print total summary
TOTAL_SUCCESS=$(echo "$RESULTS" | sed 's/\x1b\[[0-9;]*m//g' | grep '^Success:' | awk -F'\t' '{s+=$2} END {print s+0}')
TOTAL_FAILED=$(echo "$RESULTS" | sed 's/\x1b\[[0-9;]*m//g' | grep '^Failed :' | awk -F'\t' '{s+=$2} END {print s+0}')
TOTAL_ERRORS=$(echo "$RESULTS" | sed 's/\x1b\[[0-9;]*m//g' | grep '^Errors :' | awk -F'\t' '{s+=$2} END {print s+0}')

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "========================================"
printf "${GREEN}Total Success:${NC}\t${TOTAL_SUCCESS}\n"
printf "${RED}Total Failed :${NC}\t${TOTAL_FAILED}\n"
printf "${RED}Total Errors :${NC}\t${TOTAL_ERRORS}\n"
echo "========================================"

if [ -n "$OUTPUT" ]; then
    echo "$RESULTS" > "$OUTPUT"
    echo "Results written to $OUTPUT"
fi
