#!/bin/sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
SIGIL=${SIGIL:-"$ROOT/../sigil/build/dev/bin/sigil"}

cd "$ROOT/packages/sigil-bitcoin-node"

if guix shell -m ../../manifest.scm -- \
  env SIGIL_REDIRECTS=../../dev-redirects.sgl \
    "$SIGIL" eval -f ../../tools/live-testnet-probe.sgl; then
  exit 0
fi

guix shell -m ../../manifest.scm -- \
  env SIGIL_REDIRECTS=../../dev-redirects.sgl \
    "$SIGIL" eval -f ../../tools/live-testnet-status.sgl || true

exit 1
