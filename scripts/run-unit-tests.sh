#!/usr/bin/env bash
# Run from repo root: ./scripts/run-unit-tests.sh

PLENARY=${PLENARY_PATH:-$(find ~/.local/share/nvim -type d -name "plenary.nvim" 2>/dev/null | head -1)}

if [ -z "$PLENARY" ]; then
    echo "plenary.nvim not found. Set PLENARY_PATH or install it."
    exit 1
fi

nvim --headless \
    --noplugin \
    -u NONE \
    -c "set rtp+=." \
    -c "set rtp+=$PLENARY" \
    -c "runtime plugin/plenary.vim" \
    -c "lua require('plenary.test_harness').test_directory('tests', { minimal_init = 'tests/minimal_init.lua', sequential = true })" 2>&1
