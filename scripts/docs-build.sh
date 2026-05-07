#!/usr/bin/env zsh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)

PACKAGES=(
  packages/sigil-secp256k1
  packages/sigil-bitcoin-primitives
  packages/sigil-bitcoin-encoding
  packages/sigil-bitcoin-keys
  packages/sigil-bitcoin-script
  packages/sigil-bitcoin-tx
  packages/sigil-bitcoin-miniscript
)

for package in $PACKAGES; do
  (
    cd "$ROOT/$package"
    sigil build --redirects ../../dev-redirects.sgl --no-bundle
  )
done

cd "$ROOT"

sigil -L build/dev/lib eval -f tools/docs-site.sgl
