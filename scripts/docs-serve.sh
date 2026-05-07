#!/usr/bin/env zsh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
PORT="${1:-8080}"

cd "$ROOT"

SIGIL_DOCS_PORT="$PORT" sigil -L build/dev/lib eval -f tools/docs-serve.sgl
