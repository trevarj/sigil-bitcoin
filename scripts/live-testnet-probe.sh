#!/bin/sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
SIGIL=${SIGIL:-"$ROOT/../sigil/build/dev/bin/sigil"}
DATA_DIR=${SIGIL_BITCOIN_LIVE_DATA_DIR:-/tmp/sigil-bitcoin-live-probe}
CHAIN=${SIGIL_BITCOIN_LIVE_CHAIN:-bitcoin-signet}
PEERS=${SIGIL_BITCOIN_LIVE_PEERS:-}
MAX_PEERS=${SIGIL_BITCOIN_LIVE_MAX_PEERS:-35}
MAX_RETRIES=${SIGIL_BITCOIN_LIVE_MAX_RETRIES:-0}
MAX_STEPS=${SIGIL_BITCOIN_LIVE_MAX_STEPS:-64}
MAX_BLOCKS=${SIGIL_BITCOIN_LIVE_MAX_BLOCKS:-1}
MAX_SEEDS=${SIGIL_BITCOIN_LIVE_MAX_SEEDS:-8}
MAX_ADDRESSES=${SIGIL_BITCOIN_LIVE_MAX_ADDRESSES:-16}
RESOLVE_TIMEOUT=${SIGIL_BITCOIN_LIVE_RESOLVE_TIMEOUT:-2000}
CONNECT_TIMEOUT=${SIGIL_BITCOIN_LIVE_CONNECT_TIMEOUT:-5000}
READ_TIMEOUT=${SIGIL_BITCOIN_LIVE_READ_TIMEOUT:-5000}
DEADLINE=${SIGIL_BITCOIN_LIVE_DEADLINE:-120}
TCP_ONLY=${SIGIL_BITCOIN_LIVE_TCP_ONLY:-0}

usage() {
  cat <<'EOF'
usage: scripts/live-testnet-probe.sh [options]

Options:
  --peer HOST[:PORT]     Add a manual peer. Use [IPv6]:PORT for IPv6. May be repeated.
  --chain CHAIN          Chain to probe, default bitcoin-signet.
  --data-dir DIR         Probe database directory.
  --max-peers N          Maximum persisted peers to try.
  --max-retries N        Per-peer retry limit.
  --max-steps N          P2P handshake/header sync step limit.
  --max-blocks N         Maximum blocks to request after headers.
  --max-seeds N          Maximum DNS seed hosts to query.
  --max-addresses N      Maximum addresses to keep from each seed.
  --resolve-timeout N    DNS resolve timeout in milliseconds.
  --connect-timeout N    TCP connect timeout in milliseconds.
  --read-timeout N       Socket read timeout in milliseconds.
  --deadline N           Whole probe deadline in seconds, 0 disables it.
  --tcp-only             Open TCP connections only; skip Bitcoin handshake/sync.
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
    --chain)
      [ "$#" -ge 2 ] || { echo "missing value for --chain" >&2; exit 2; }
      CHAIN=$2
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
    --max-seeds)
      [ "$#" -ge 2 ] || { echo "missing value for --max-seeds" >&2; exit 2; }
      MAX_SEEDS=$2
      shift 2
      ;;
    --max-addresses)
      [ "$#" -ge 2 ] || { echo "missing value for --max-addresses" >&2; exit 2; }
      MAX_ADDRESSES=$2
      shift 2
      ;;
    --resolve-timeout)
      [ "$#" -ge 2 ] || { echo "missing value for --resolve-timeout" >&2; exit 2; }
      RESOLVE_TIMEOUT=$2
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
    --deadline)
      [ "$#" -ge 2 ] || { echo "missing value for --deadline" >&2; exit 2; }
      DEADLINE=$2
      shift 2
      ;;
    --tcp-only)
      TCP_ONLY=1
      shift
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

set -- probe \
  --chain "$CHAIN" \
  --data-dir "$DATA_DIR" \
  --max-peers "$MAX_PEERS" \
  --max-retries "$MAX_RETRIES" \
  --max-steps "$MAX_STEPS" \
  --max-blocks "$MAX_BLOCKS" \
  --max-seeds "$MAX_SEEDS" \
  --max-addresses "$MAX_ADDRESSES" \
  --resolve-timeout "$RESOLVE_TIMEOUT" \
  --connect-timeout "$CONNECT_TIMEOUT" \
  --read-timeout "$READ_TIMEOUT"

if [ "$TCP_ONLY" -eq 1 ]; then
  set -- "$@" --tcp-only
fi

if [ -n "$PEERS" ]; then
  for peer in $PEERS; do
    set -- "$@" --peer "$peer"
  done
fi

run_probe_command() {
  if [ "$DEADLINE" -gt 0 ]; then
    if ! command -v timeout >/dev/null 2>&1; then
      echo "timeout command is required for --deadline; rerun with --deadline 0 to disable" >&2
      exit 2
    fi
    timeout --kill-after=5s "${DEADLINE}s" \
      guix shell -m ../../manifest.scm -- \
        "$SIGIL" run --redirects ../../dev-redirects.sgl -- "$@"
  else
    guix shell -m ../../manifest.scm -- \
      "$SIGIL" run --redirects ../../dev-redirects.sgl -- "$@"
  fi
}

set +e
run_probe_command "$@"
probe_status=$?
set -e
if [ "$probe_status" -eq 0 ]; then
  exit 0
fi
if [ "$probe_status" -eq 124 ] || [ "$probe_status" -eq 137 ]; then
  echo "probe-deadline: exceeded ${DEADLINE}s" >&2
fi

guix shell -m ../../manifest.scm -- \
  "$SIGIL" run --redirects ../../dev-redirects.sgl -- \
    status --chain "$CHAIN" --data-dir "$DATA_DIR" || true

guix shell -m ../../manifest.scm -- \
  "$SIGIL" run --redirects ../../dev-redirects.sgl -- \
    peers summary --chain "$CHAIN" --data-dir "$DATA_DIR" || true

guix shell -m ../../manifest.scm -- \
  "$SIGIL" run --redirects ../../dev-redirects.sgl -- \
    peers list --chain "$CHAIN" --data-dir "$DATA_DIR" || true

exit 1
