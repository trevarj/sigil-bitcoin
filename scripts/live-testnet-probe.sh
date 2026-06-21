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
BLOCK_CATCHUP_BLOCKS=${SIGIL_BITCOIN_LIVE_BLOCK_CATCHUP_BLOCKS:-16}
BLOCK_CATCHUP_INTERVAL=${SIGIL_BITCOIN_LIVE_BLOCK_CATCHUP_INTERVAL:-1}
HEADER_REFRESH_INTERVAL=${SIGIL_BITCOIN_LIVE_HEADER_REFRESH_INTERVAL:-8}
VALIDATION_BLOCKS=${SIGIL_BITCOIN_LIVE_VALIDATION_BLOCKS:-128}
MAX_SEEDS=${SIGIL_BITCOIN_LIVE_MAX_SEEDS:-8}
MAX_ADDRESSES=${SIGIL_BITCOIN_LIVE_MAX_ADDRESSES:-16}
RESOLVE_TIMEOUT=${SIGIL_BITCOIN_LIVE_RESOLVE_TIMEOUT:-2000}
CONNECT_TIMEOUT=${SIGIL_BITCOIN_LIVE_CONNECT_TIMEOUT:-5000}
READ_TIMEOUT=${SIGIL_BITCOIN_LIVE_READ_TIMEOUT:-5000}
DEADLINE=${SIGIL_BITCOIN_LIVE_DEADLINE:-120}
TCP_ONLY=${SIGIL_BITCOIN_LIVE_TCP_ONLY:-0}
SOCKS5=${SIGIL_BITCOIN_LIVE_SOCKS5:-}
MODE=${SIGIL_BITCOIN_LIVE_MODE:-probe}
RETRY_DELAY=${SIGIL_BITCOIN_LIVE_RETRY_DELAY:-0}
GUARD_PADDING=${SIGIL_BITCOIN_LIVE_GUARD_PADDING:-90}
LIST_PEERS=${SIGIL_BITCOIN_LIVE_LIST_PEERS:-0}

usage() {
  cat <<'EOF'
usage: scripts/live-testnet-probe.sh [options]

Options:
  --mode MODE           Command mode: probe, run, sync, header-sync, or block-sync.
  --peer HOST[:PORT]     Add a manual peer. Use [IPv6]:PORT for IPv6. May be repeated.
  --chain CHAIN          Chain to probe, default bitcoin-signet.
  --data-dir DIR         Probe database directory.
  --max-peers N          Maximum persisted peers to try.
  --max-retries N        Per-peer retry limit.
  --max-steps N          P2P handshake/header sync step limit.
  --max-blocks N         Maximum blocks to request after headers.
  --block-catchup-blocks N
                         Run-mode block batch size for catch-up attempts.
  --block-catchup-interval N
                         Run-mode interval for block catch-up while headers lag.
  --header-refresh-interval N
                         Run-mode interval for header refresh while blocks catch up.
  --validation-blocks N  Run-mode local validation batch size.
  --max-seeds N          Maximum DNS seed hosts to query.
  --max-addresses N      Maximum addresses to keep from each seed.
  --retry-delay N        Delay in seconds between run/sync retries.
  --resolve-timeout N    DNS resolve timeout in milliseconds.
  --connect-timeout N    TCP connect timeout in milliseconds.
  --read-timeout N       Socket read timeout in milliseconds.
  --deadline N           Whole probe deadline in seconds, 0 disables it.
  --guard-padding N      Extra seconds for Guix/build startup before timeout guard.
  --socks5 HOST[:PORT]   Connect peers through a SOCKS5 proxy, default port 9050.
  --list-peers           Print the full peer list when the probe fails.
  --tcp-only             Open TCP connections only; skip Bitcoin handshake/sync.
  -h, --help             Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode)
      [ "$#" -ge 2 ] || { echo "missing value for --mode" >&2; exit 2; }
      MODE=$2
      shift 2
      ;;
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
    --block-catchup-blocks)
      [ "$#" -ge 2 ] || { echo "missing value for --block-catchup-blocks" >&2; exit 2; }
      BLOCK_CATCHUP_BLOCKS=$2
      shift 2
      ;;
    --block-catchup-interval)
      [ "$#" -ge 2 ] || { echo "missing value for --block-catchup-interval" >&2; exit 2; }
      BLOCK_CATCHUP_INTERVAL=$2
      shift 2
      ;;
    --header-refresh-interval)
      [ "$#" -ge 2 ] || { echo "missing value for --header-refresh-interval" >&2; exit 2; }
      HEADER_REFRESH_INTERVAL=$2
      shift 2
      ;;
    --validation-blocks)
      [ "$#" -ge 2 ] || { echo "missing value for --validation-blocks" >&2; exit 2; }
      VALIDATION_BLOCKS=$2
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
    --retry-delay)
      [ "$#" -ge 2 ] || { echo "missing value for --retry-delay" >&2; exit 2; }
      RETRY_DELAY=$2
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
    --guard-padding)
      [ "$#" -ge 2 ] || { echo "missing value for --guard-padding" >&2; exit 2; }
      GUARD_PADDING=$2
      shift 2
      ;;
    --socks5)
      [ "$#" -ge 2 ] || { echo "missing value for --socks5" >&2; exit 2; }
      SOCKS5=$2
      shift 2
      ;;
    --tcp-only)
      TCP_ONLY=1
      shift
      ;;
    --list-peers)
      LIST_PEERS=1
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

case "$MODE" in
  probe|run|sync|header-sync|block-sync) ;;
  *)
    echo "unknown mode: $MODE" >&2
    usage >&2
    exit 2
    ;;
esac

set -- "$MODE" \
  --chain "$CHAIN" \
  --data-dir "$DATA_DIR" \
  --max-peers "$MAX_PEERS" \
  --max-retries "$MAX_RETRIES" \
  --max-steps "$MAX_STEPS" \
  --max-blocks "$MAX_BLOCKS" \
  --block-catchup-blocks "$BLOCK_CATCHUP_BLOCKS" \
  --block-catchup-interval "$BLOCK_CATCHUP_INTERVAL" \
  --header-refresh-interval "$HEADER_REFRESH_INTERVAL" \
  --validation-blocks "$VALIDATION_BLOCKS" \
  --max-seeds "$MAX_SEEDS" \
  --max-addresses "$MAX_ADDRESSES" \
  --resolve-timeout "$RESOLVE_TIMEOUT" \
  --connect-timeout "$CONNECT_TIMEOUT" \
  --read-timeout "$READ_TIMEOUT"

if [ "$MODE" = "run" ] || [ "$MODE" = "sync" ] || [ "$MODE" = "header-sync" ] || [ "$MODE" = "block-sync" ]; then
  set -- "$@" --iterations 0 --retry-delay "$RETRY_DELAY"
  if [ "$DEADLINE" -gt 0 ]; then
    set -- "$@" --deadline-ms "$((DEADLINE * 1000))"
  fi
fi

if [ "$TCP_ONLY" -eq 1 ]; then
  if [ "$MODE" != "probe" ]; then
    echo "--tcp-only is only valid with --mode probe" >&2
    exit 2
  fi
  set -- "$@" --tcp-only
fi

if [ -n "$SOCKS5" ]; then
  set -- "$@" --socks5 "$SOCKS5"
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
    guard_seconds=$((DEADLINE + GUARD_PADDING))
    timeout --kill-after=5s "${guard_seconds}s" \
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
  guix shell -m ../../manifest.scm -- \
    "$SIGIL" run --redirects ../../dev-redirects.sgl -- \
      run --chain "$CHAIN" --data-dir "$DATA_DIR" \
      --iterations 0 --deadline-ms 1 --max-peers 1 --max-retries 0 \
      --retry-delay 0 --resolve-timeout 1 --connect-timeout 1 \
      --read-timeout 1 >/dev/null 2>&1 || true
fi

guix shell -m ../../manifest.scm -- \
  "$SIGIL" run --redirects ../../dev-redirects.sgl -- \
    status --chain "$CHAIN" --data-dir "$DATA_DIR" || true

guix shell -m ../../manifest.scm -- \
  "$SIGIL" run --redirects ../../dev-redirects.sgl -- \
    peers summary --chain "$CHAIN" --data-dir "$DATA_DIR" || true

if [ "$LIST_PEERS" -eq 1 ]; then
  guix shell -m ../../manifest.scm -- \
    "$SIGIL" run --redirects ../../dev-redirects.sgl -- \
      peers list --chain "$CHAIN" --data-dir "$DATA_DIR" || true
fi

exit 1
