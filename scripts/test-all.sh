#!/bin/sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)

link_package_deps() {
  package_dir=$1
  mkdir -p "$package_dir/.sigil"

  if [ -e "$package_dir/.sigil/deps" ] && [ ! -L "$package_dir/.sigil/deps" ]; then
    # Keep package-local caches produced by `sigil deps install`.
    return 0
  fi

  # Package-local native test runs use the workspace dependency cache.
  ln -sfn "../../../.sigil/deps" "$package_dir/.sigil/deps"
}

printf '\n==> root workspace tests\n'
cd "$ROOT"
guix shell -m manifest.scm -- \
  sigil test --redirects ./dev-redirects.sgl --no-color

printf '\n==> sigil-secp256k1 native harness\n'
link_package_deps "$ROOT/packages/sigil-secp256k1"
cd "$ROOT/packages/sigil-secp256k1"
guix shell -m ../../manifest.scm -- \
  sigil test test/test-secp256k1.sgl \
    --redirects ../../dev-redirects.sgl --no-color

printf '\n==> sigil-bitcoin-keys native harness\n'
link_package_deps "$ROOT/packages/sigil-bitcoin-keys"
cd "$ROOT/packages/sigil-bitcoin-keys"
guix shell -m ../../manifest.scm -- \
  sigil test test/test-keys.sgl \
    --redirects ../../dev-redirects.sgl --no-color

printf '\n==> sigil-bitcoin-tx native harness\n'
link_package_deps "$ROOT/packages/sigil-bitcoin-tx"
cd "$ROOT/packages/sigil-bitcoin-tx"
guix shell -m ../../manifest.scm -- \
  sigil test test/test-tx.sgl \
    --redirects ../../dev-redirects.sgl --no-color

printf '\n==> sigil-bitcoin-miniscript native harness\n'
link_package_deps "$ROOT/packages/sigil-bitcoin-miniscript"
cd "$ROOT/packages/sigil-bitcoin-miniscript"
guix shell -m ../../manifest.scm -- \
  sigil test test/test-miniscript.sgl \
    --redirects ../../dev-redirects.sgl --no-color
