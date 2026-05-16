#!/bin/sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

status=0

report_count() {
  label=$1
  count=$2
  printf '%s: %s\n' "$label" "$count"
}

missing_docs=$(rg -o --no-heading --color never "No docstring yet" public/api 2>/dev/null | wc -l | tr -d ' ')
report_count "generated API placeholders" "$missing_docs"

tools_triple_comments=$(rg -n --no-heading --color never '^\s+;;;' tools 2>/dev/null | wc -l | tr -d ' ')
report_count "tools indented triple-semicolon comments" "$tools_triple_comments"

underscore_paths=$(rg --files \
  | rg '(^|/)[^/]*_[^/]*$' \
  | rg -v '^packages/sigil-bitcoin-demo/wasm-include/sigil_mbedtls_config\.h$' \
  | wc -l | tr -d ' ')
report_count "underscore paths" "$underscore_paths"

vector_files=$(fd --color never -t f . tests/vectors 2>/dev/null | wc -l | tr -d ' ')
report_count "test vector files" "$vector_files"

printf 'inline spec coverage:\n'
for path in \
  tools/docs-site.sgl \
  tools/docs-serve.sgl \
  packages/sigil-bitcoin-demo/src/sigil/bitcoin/demo.sgl \
  packages/sigil-bitcoin-encoding/src/sigil/bitcoin/encoding.sgl \
  packages/sigil-bitcoin-primitives/src/sigil/bitcoin/primitives.sgl \
  packages/sigil-bitcoin-tx/src/sigil/bitcoin/psbt/*.sgl
do
  defines=$(rg -c '^\s*\(define \(' "$path" 2>/dev/null || printf '0')
  specs=$(rg -c '^\s*\(: ' "$path" 2>/dev/null || printf '0')
  printf '  %s: %s specs / %s defines\n' "$path" "$specs" "$defines"
done

if [ "$vector_files" -eq 0 ]; then
  echo "standards-check: tests/vectors is empty" >&2
  status=1
fi

exit "$status"
