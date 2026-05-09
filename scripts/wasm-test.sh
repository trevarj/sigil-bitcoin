#!/bin/sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
DEMO="$ROOT/packages/sigil-bitcoin-demo"
WWW="$DEMO/build/web/www"
WASM="$WWW/sigil-bitcoin-demo.wasm"
BUNDLE="$WWW/lib.bundle"

printf '\n==> sigil-bitcoin-demo wasm build\n'
(
  cd "$DEMO"
  guix shell -m ../../manifest.scm -- \
    sigil build \
      --config web \
      --redirects ../../dev-redirects.sgl
)

for artifact in "$WASM" "$BUNDLE"; do
  if [ ! -s "$artifact" ]; then
    echo "wasm-test: missing or empty artifact: $artifact" >&2
    exit 1
  fi
done

printf 'wasm-test: artifacts present\n'

dump=$(mktemp "${TMPDIR:-/tmp}/sigil-bitcoin-wasm.XXXXXX")
trap 'rm -f "$dump"' EXIT

guix shell -m "$ROOT/manifest.scm" -- wasm-objdump -x "$WASM" > "$dump"

for export in malloc free sigil_web_init sigil_web_start sigil_web_eval sigil_web_input; do
  if ! grep -q -- "-> \"$export\"" "$dump"; then
    echo "wasm-test: missing WASM export: $export" >&2
    exit 1
  fi
done

if ! grep -q -- "wasi_snapshot_preview1" "$dump"; then
  echo "wasm-test: expected WASI imports in $WASM" >&2
  exit 1
fi

printf 'wasm-test: wasm exports and WASI imports validated\n'

if command -v wasmtime >/dev/null 2>&1; then
  printf '\n==> sigil-bitcoin-demo wasm smoke test\n'
  wasmtime --mapdir /lib::"$WWW/lib" "$WASM" | grep -q "sigil-bitcoin demo runtime ready"
  printf 'wasm-test: wasmtime smoke test passed\n'
else
  printf 'wasm-test: wasmtime not found; runtime smoke test skipped\n'
fi
