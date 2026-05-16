#!/usr/bin/env zsh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
PRESS_TOOL="$ROOT/tools/press-docs"
DEP_ROOT="$PRESS_TOOL/.sigil/deps"

PACKAGES=(
  packages/sigil-secp256k1
  packages/sigil-bitcoin-primitives
  packages/sigil-bitcoin-encoding
  packages/sigil-bitcoin-keys
  packages/sigil-bitcoin-script
  packages/sigil-bitcoin-tx
  packages/sigil-bitcoin-miniscript
)

link_package_deps() {
  local package_dir=$1
  mkdir -p "$package_dir/.sigil"

  if [ -L "$package_dir/.sigil/deps" ]; then
    return 0
  fi

  if [ -d "$package_dir/.sigil/deps" ]; then
    for dep in "$ROOT"/.sigil/deps/*; do
      ln -sfn "$dep" "$package_dir/.sigil/deps/$(basename "$dep")"
    done
  else
    ln -sfn "../../../.sigil/deps" "$package_dir/.sigil/deps"
  fi
}

if [ ! -d "$DEP_ROOT/press" ]; then
  (
    cd "$PRESS_TOOL"
    sigil deps install
  )
fi

for package in $PACKAGES; do
  link_package_deps "$ROOT/$package"
  (
    cd "$ROOT/$package"
    sigil build --redirects ../../dev-redirects.sgl --no-bundle
  )
done

lib_args=()
for src_dir in "$DEP_ROOT"/*/src; do
  if [ -d "$src_dir" ]; then
    lib_args+=(-L "$src_dir")
  fi
done

cd "$ROOT"
rm -rf public

sigil "${lib_args[@]}" \
  -L packages/sigil-bitcoin-miniscript/build/dev/lib \
  eval -f tools/press-site.sgl

cp tools/press-search-index.json public/search-index.json
