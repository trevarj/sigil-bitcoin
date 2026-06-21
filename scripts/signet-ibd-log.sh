#!/bin/sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
SIGIL=${SIGIL:-"$ROOT/../sigil/build/dev/bin/sigil"}
DATA_DIR=${SIGIL_BITCOIN_IBD_DATA_DIR:-/tmp/sigil-bitcoin-signet-ibd}
LOG_DIR=${SIGIL_BITCOIN_IBD_LOG_DIR:-/tmp/sigil-bitcoin-signet-ibd-logs}
ROUNDS=${SIGIL_BITCOIN_IBD_ROUNDS:-0}
ROUND_DEADLINE=${SIGIL_BITCOIN_IBD_ROUND_DEADLINE:-1800}
GUARD_PADDING=${SIGIL_BITCOIN_IBD_GUARD_PADDING:-180}
MAX_PEERS=${SIGIL_BITCOIN_IBD_MAX_PEERS:-12}
MAX_SEEDS=${SIGIL_BITCOIN_IBD_MAX_SEEDS:-2}
MAX_ADDRESSES=${SIGIL_BITCOIN_IBD_MAX_ADDRESSES:-24}
MAX_STEPS=${SIGIL_BITCOIN_IBD_MAX_STEPS:-32}
MAX_BLOCKS=${SIGIL_BITCOIN_IBD_MAX_BLOCKS:-1}
BLOCK_CATCHUP_BLOCKS=${SIGIL_BITCOIN_IBD_BLOCK_CATCHUP_BLOCKS:-64}
BLOCK_CATCHUP_INTERVAL=${SIGIL_BITCOIN_IBD_BLOCK_CATCHUP_INTERVAL:-1}
HEADER_REFRESH_INTERVAL=${SIGIL_BITCOIN_IBD_HEADER_REFRESH_INTERVAL:-8}
VALIDATION_BLOCKS=${SIGIL_BITCOIN_IBD_VALIDATION_BLOCKS:-128}
RESOLVE_TIMEOUT=${SIGIL_BITCOIN_IBD_RESOLVE_TIMEOUT:-3000}
CONNECT_TIMEOUT=${SIGIL_BITCOIN_IBD_CONNECT_TIMEOUT:-7000}
READ_TIMEOUT=${SIGIL_BITCOIN_IBD_READ_TIMEOUT:-7000}
RETRY_DELAY=${SIGIL_BITCOIN_IBD_RETRY_DELAY:-0}
SOCKS5=${SIGIL_BITCOIN_IBD_SOCKS5:-}

usage() {
  cat <<'EOF'
usage: scripts/signet-ibd-log.sh [options]

Runs repeated bounded bitcoin-signet `run` rounds and writes a timestamped log.
Default networking is direct TCP. Use --socks5 HOST[:PORT] only when needed.

Options:
  --data-dir DIR             Node database directory.
  --log-dir DIR              Directory for timestamped logs.
  --rounds N                 Number of rounds, 0 means until interrupted.
  --round-deadline N         Per-round deadline in seconds.
  --max-peers N              Persisted peers to try per round.
  --max-seeds N              DNS seed hosts to query when peer DB is empty.
  --max-addresses N          Addresses to keep per seed.
  --max-steps N              P2P message step limit.
  --max-blocks N             Normal sync block batch size.
  --block-catchup-blocks N   Run-mode block batch size.
  --block-catchup-interval N Run-mode block catch-up attempt interval.
  --header-refresh-interval N
                             Run-mode header refresh interval while catching up.
  --validation-blocks N      Run-mode local validation batch size.
  --resolve-timeout N        DNS resolve timeout in milliseconds.
  --connect-timeout N        TCP connect timeout in milliseconds.
  --read-timeout N           Socket read timeout in milliseconds.
  --retry-delay N            Delay in seconds between retry attempts.
  --guard-padding N          Extra seconds for Guix/build startup guard.
  --socks5 HOST[:PORT]       Route peer connections through SOCKS5.
  -h, --help                 Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --data-dir)
      [ "$#" -ge 2 ] || { echo "missing value for --data-dir" >&2; exit 2; }
      DATA_DIR=$2
      shift 2
      ;;
    --log-dir)
      [ "$#" -ge 2 ] || { echo "missing value for --log-dir" >&2; exit 2; }
      LOG_DIR=$2
      shift 2
      ;;
    --rounds)
      [ "$#" -ge 2 ] || { echo "missing value for --rounds" >&2; exit 2; }
      ROUNDS=$2
      shift 2
      ;;
    --round-deadline)
      [ "$#" -ge 2 ] || { echo "missing value for --round-deadline" >&2; exit 2; }
      ROUND_DEADLINE=$2
      shift 2
      ;;
    --max-peers)
      [ "$#" -ge 2 ] || { echo "missing value for --max-peers" >&2; exit 2; }
      MAX_PEERS=$2
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
    --retry-delay)
      [ "$#" -ge 2 ] || { echo "missing value for --retry-delay" >&2; exit 2; }
      RETRY_DELAY=$2
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

mkdir -p "$LOG_DIR"
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
LOG_FILE="$LOG_DIR/signet-ibd-$timestamp.log"

status_command() {
  (
    cd "$ROOT/packages/sigil-bitcoin-node"
    guix shell -m ../../manifest.scm -- \
      "$SIGIL" run --redirects ../../dev-redirects.sgl -- \
        status --chain bitcoin-signet --data-dir "$DATA_DIR"
  )
}

summary_command() {
  (
    cd "$ROOT/packages/sigil-bitcoin-node"
    guix shell -m ../../manifest.scm -- \
      "$SIGIL" run --redirects ../../dev-redirects.sgl -- \
        peers summary --chain bitcoin-signet --data-dir "$DATA_DIR"
  )
}

append_status() {
  {
    echo
    echo "==> final status $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    status_command || true
    echo
    echo "==> peer summary $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    summary_command || true
  } 2>&1 | tee -a "$LOG_FILE"
}

append_analysis() {
  {
    echo
    echo "==> IBD analysis $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    "$ROOT/scripts/signet-ibd-analyze.sh" "$LOG_FILE"
  } 2>&1 | tee -a "$LOG_FILE"
}

on_interrupt() {
  echo "signet-ibd-log: interrupted; writing final status to $LOG_FILE" >&2
  append_status
  append_analysis
  exit 130
}

trap on_interrupt INT TERM

{
  echo "signet-ibd-log-start: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "data-dir: $DATA_DIR"
  echo "log-file: $LOG_FILE"
  echo "rounds: $ROUNDS"
  echo "round-deadline: $ROUND_DEADLINE"
  echo "network: $(if [ -n "$SOCKS5" ]; then echo "socks5 $SOCKS5"; else echo "direct"; fi)"
  echo "max-peers: $MAX_PEERS"
  echo "max-seeds: $MAX_SEEDS"
  echo "max-addresses: $MAX_ADDRESSES"
  echo "max-steps: $MAX_STEPS"
  echo "max-blocks: $MAX_BLOCKS"
  echo "block-catchup-blocks: $BLOCK_CATCHUP_BLOCKS"
  echo "block-catchup-interval: $BLOCK_CATCHUP_INTERVAL"
  echo "header-refresh-interval: $HEADER_REFRESH_INTERVAL"
  echo "validation-blocks: $VALIDATION_BLOCKS"
  echo "resolve-timeout: $RESOLVE_TIMEOUT"
  echo "connect-timeout: $CONNECT_TIMEOUT"
  echo "read-timeout: $READ_TIMEOUT"
  echo "retry-delay: $RETRY_DELAY"
  echo "guard-padding: $GUARD_PADDING"
  echo
  echo "==> initial status"
  status_command || true
} 2>&1 | tee -a "$LOG_FILE"

round=0
while [ "$ROUNDS" -eq 0 ] || [ "$round" -lt "$ROUNDS" ]; do
  round=$((round + 1))
  {
    echo
    echo "==> round $round start $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } | tee -a "$LOG_FILE"

  set +e
  status_file="$LOG_DIR/.signet-ibd-status-$$"
  set -- \
    --mode run \
    --chain bitcoin-signet \
    --data-dir "$DATA_DIR" \
    --deadline "$ROUND_DEADLINE" \
    --guard-padding "$GUARD_PADDING" \
    --max-peers "$MAX_PEERS" \
    --max-seeds "$MAX_SEEDS" \
    --max-addresses "$MAX_ADDRESSES" \
    --max-steps "$MAX_STEPS" \
    --max-blocks "$MAX_BLOCKS" \
    --block-catchup-blocks "$BLOCK_CATCHUP_BLOCKS" \
    --block-catchup-interval "$BLOCK_CATCHUP_INTERVAL" \
    --header-refresh-interval "$HEADER_REFRESH_INTERVAL" \
    --validation-blocks "$VALIDATION_BLOCKS" \
    --resolve-timeout "$RESOLVE_TIMEOUT" \
    --connect-timeout "$CONNECT_TIMEOUT" \
    --read-timeout "$READ_TIMEOUT" \
    --retry-delay "$RETRY_DELAY"
  if [ -n "$SOCKS5" ]; then
    ( "$ROOT/scripts/live-testnet-probe.sh" "$@" --socks5 "$SOCKS5"; echo "$?" > "$status_file" ) 2>&1 | tee -a "$LOG_FILE"
  else
    ( "$ROOT/scripts/live-testnet-probe.sh" "$@"; echo "$?" > "$status_file" ) 2>&1 | tee -a "$LOG_FILE"
  fi
  probe_status=$(cat "$status_file")
  rm -f "$status_file"
  set -e

  {
    echo "==> round $round exit $probe_status $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } | tee -a "$LOG_FILE"
done

append_status
append_analysis
echo "signet-ibd-log: wrote $LOG_FILE"
