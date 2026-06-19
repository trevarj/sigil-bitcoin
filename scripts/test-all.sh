#!/bin/sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)

setup_native_library_path() {
  libsecp_dir=$(guix build libsecp256k1 2>/dev/null)/lib
  if [ -d "$libsecp_dir" ]; then
    if [ "${LD_LIBRARY_PATH:-}" ]; then
      LD_LIBRARY_PATH="$libsecp_dir:$LD_LIBRARY_PATH"
    else
      LD_LIBRARY_PATH="$libsecp_dir"
    fi
    export LD_LIBRARY_PATH
  fi
}

link_package_deps() {
  package_dir=$1
  mkdir -p "$package_dir/.sigil"

  if [ -L "$package_dir/.sigil/deps" ]; then
    return 0
  fi

  if [ -d "$package_dir/.sigil/deps" ]; then
    # Keep package-local caches but refresh links from the workspace cache.
    for dep in "$ROOT"/.sigil/deps/*; do
      ln -sfn "$dep" "$package_dir/.sigil/deps/$(basename "$dep")"
    done
  else
    # Package-local native test runs use the workspace dependency cache.
    ln -sfn "../../../.sigil/deps" "$package_dir/.sigil/deps"
  fi
}

setup_native_library_path

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

printf '\n==> sigil-bitcoin-consensus package harness\n'
link_package_deps "$ROOT/packages/sigil-bitcoin-consensus"
cd "$ROOT/packages/sigil-bitcoin-consensus"
guix shell -m ../../manifest.scm -- \
  sigil test test/test-consensus.sgl \
    --redirects ../../dev-redirects.sgl --no-color

"$ROOT/scripts/wasm-test.sh"
