#!/usr/bin/env bash
# Full site build: renders every document to HTML and PDF into docs/, then checks the result.
# Always use this (or plain `quarto render`) -- never `quarto render --to <format>` on the whole
# project, which prunes the other format's outputs repo-wide.
set -euo pipefail
cd "$(dirname "$0")/.."
quarto render
python3 scripts/check_site.py
