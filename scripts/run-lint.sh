#!/usr/bin/env bash
# Run from repo root: ./scripts/run-lint.sh

set -e

printf "Running selene\n"
selene --display-style quiet .

printf "\nRunning stylua\n"
stylua --check --output-format summary .
