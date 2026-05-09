#!/bin/sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
WORKTREE="${SIGIL_BITCOIN_PAGES_WORKTREE:-$ROOT/.pages-worktree}"

cd "$ROOT"

if [ ! -f public/index.html ]; then
  echo "pages-publish: public/index.html is missing; run scripts/pages-build.sh first" >&2
  exit 1
fi

if [ -d "$WORKTREE" ]; then
  git worktree remove "$WORKTREE"
fi

git worktree add -B pages "$WORKTREE"

(
  cd "$WORKTREE"
  git rm -qr . || true
)

cp -R "$ROOT/public/." "$WORKTREE/"

(
  cd "$WORKTREE"
  git add -A
  if git diff --cached --quiet; then
    echo "pages-publish: no changes to publish."
  else
    git commit -m "docs: publish Codeberg Pages site"
    echo "pages-publish: push with: git push origin pages"
  fi
)
