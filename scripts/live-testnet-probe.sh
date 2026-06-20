#!/bin/sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
SIGIL=${SIGIL:-"$ROOT/../sigil/build/dev/bin/sigil"}
DATA_DIR=${SIGIL_BITCOIN_LIVE_DATA_DIR:-/tmp/sigil-bitcoin-live-probe}
PEERS=${SIGIL_BITCOIN_LIVE_PEERS:-}
MAX_PEERS=${SIGIL_BITCOIN_LIVE_MAX_PEERS:-35}
MAX_RETRIES=${SIGIL_BITCOIN_LIVE_MAX_RETRIES:-0}
MAX_STEPS=${SIGIL_BITCOIN_LIVE_MAX_STEPS:-64}
MAX_BLOCKS=${SIGIL_BITCOIN_LIVE_MAX_BLOCKS:-1}
CONNECT_TIMEOUT=${SIGIL_BITCOIN_LIVE_CONNECT_TIMEOUT:-5000}
READ_TIMEOUT=${SIGIL_BITCOIN_LIVE_READ_TIMEOUT:-5000}

usage() {
  cat <<'EOF'
usage: scripts/live-testnet-probe.sh [options]

Options:
  --peer HOST:PORT       Add a manual testnet peer. May be repeated.
  --data-dir DIR         Probe database directory.
  --max-peers N          Maximum persisted peers to try.
  --max-retries N        Per-peer retry limit.
  --max-steps N          P2P handshake/header sync step limit.
  --max-blocks N         Maximum blocks to request after headers.
  --connect-timeout N    TCP connect timeout in milliseconds.
  --read-timeout N       Socket read timeout in milliseconds.
  -h, --help             Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --peer)
      [ "$#" -ge 2 ] || { echo "missing value for --peer" >&2; exit 2; }
      if [ -n "$PEERS" ]; then
        PEERS="$PEERS $2"
      else
        PEERS="$2"
      fi
      shift 2
      ;;
    --data-dir)
      [ "$#" -ge 2 ] || { echo "missing value for --data-dir" >&2; exit 2; }
      DATA_DIR=$2
      shift 2
      ;;
    --max-peers)
      [ "$#" -ge 2 ] || { echo "missing value for --max-peers" >&2; exit 2; }
      MAX_PEERS=$2
      shift 2
      ;;
    --max-retries)
      [ "$#" -ge 2 ] || { echo "missing value for --max-retries" >&2; exit 2; }
      MAX_RETRIES=$2
      shift 2
      ;;
    --max-steps)
      [ "$#" -ge 2 ] || { echo "missing value for --max-steps" >&2; exit 2; }
      MAX_STEPS=$2
      shift 2
      ;;
    --max-blocks)
      [ "$#" -ge 2 ] || { echo "missing value for --max-blocks" >&2; exit 2; }
      MAX_BLOCKS=$2
      shift 2
      ;;
    --connect-timeout)
      [ "$#" -ge 2 ] || { echo "missing value for --connect-timeout" >&2; exit 2; }
      CONNECT_TIMEOUT=$2
      shift 2
      ;;
    --read-timeout)
      [ "$#" -ge 2 ] || { echo "missing value for --read-timeout" >&2; exit 2; }
      READ_TIMEOUT=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

cd "$ROOT/packages/sigil-bitcoin-node"

if guix shell -m ../../manifest.scm -- \
  env SIGIL_REDIRECTS=../../dev-redirects.sgl \
    SIGIL_BITCOIN_LIVE_DATA_DIR="$DATA_DIR" \
    SIGIL_BITCOIN_LIVE_PEERS="$PEERS" \
    SIGIL_BITCOIN_LIVE_MAX_PEERS="$MAX_PEERS" \
    SIGIL_BITCOIN_LIVE_MAX_RETRIES="$MAX_RETRIES" \
    SIGIL_BITCOIN_LIVE_MAX_STEPS="$MAX_STEPS" \
    SIGIL_BITCOIN_LIVE_MAX_BLOCKS="$MAX_BLOCKS" \
    SIGIL_BITCOIN_LIVE_CONNECT_TIMEOUT="$CONNECT_TIMEOUT" \
    SIGIL_BITCOIN_LIVE_READ_TIMEOUT="$READ_TIMEOUT" \
    "$SIGIL" eval -f ../../tools/live-testnet-probe.sgl; then
  exit 0
fi

guix shell -m ../../manifest.scm -- \
  env SIGIL_REDIRECTS=../../dev-redirects.sgl \
    SIGIL_BITCOIN_LIVE_DATA_DIR="$DATA_DIR" \
    "$SIGIL" eval -f ../../tools/live-testnet-status.sgl || true

exit 1
