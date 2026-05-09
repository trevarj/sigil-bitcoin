#!/bin/sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)

cd "$ROOT"

guix shell -m manifest.scm -- ./scripts/docs-build.sh

(
  cd "$ROOT/packages/sigil-bitcoin-demo"
  guix shell -m ../../manifest.scm -- \
    sigil build \
    --config web \
    --redirects ../../dev-redirects.sgl \
    --force
)

mkdir -p public/assets/wasm

for artifact in sigil-bitcoin-demo.wasm lib.bundle; do
  src="packages/sigil-bitcoin-demo/build/web/www/$artifact"
  if [ ! -f "$src" ]; then
    echo "pages-build: missing $src" >&2
    exit 1
  fi
  cp "$src" "public/assets/wasm/$artifact"
done

echo "Wrote public/ with live WASM assets."
