#!/bin/sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)

printf '\n==> root workspace tests\n'
cd "$ROOT"
guix shell -m manifest.scm -- \
  sigil test --redirects ./dev-redirects.sgl --no-color

printf '\n==> sigil-secp256k1 native harness\n'
cd "$ROOT/packages/sigil-secp256k1"
guix shell -m ../../manifest.scm -- \
  sigil test test/test-secp256k1.sgl \
    --redirects ../../dev-redirects.sgl --no-color

printf '\n==> sigil-bitcoin-keys native harness\n'
cd "$ROOT/packages/sigil-bitcoin-keys"
guix shell -m ../../manifest.scm -- \
  sigil test test/test-keys.sgl \
    --redirects ../../dev-redirects.sgl --no-color
