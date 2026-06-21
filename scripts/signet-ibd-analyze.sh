#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
usage: scripts/signet-ibd-analyze.sh LOGFILE

Summarizes a signet IBD log produced by scripts/signet-ibd-log.sh.
EOF
}

if [ "$#" -eq 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
  usage
  exit 0
fi

if [ "$#" -ne 1 ]; then
  usage >&2
  exit 2
fi

LOG_FILE=$1
if [ ! -f "$LOG_FILE" ]; then
  echo "missing log file: $LOG_FILE" >&2
  exit 2
fi

awk '
function num(value) {
  if (value == "" || value == "#f") {
    return 0
  }
  return value + 0
}

function remember_status(key, value) {
  if (key == "best-height" || key == "headers" ||
      key == "blocks" || key == "validated-blocks" ||
      key == "best-block-height" || key == "pending-blocks" ||
      key == "requested-blocks" || key == "failed-blocks" ||
      key == "sync-stage" || key == "sync-last-error" ||
      key == "run-attempts" || key == "run-last-result" ||
      key == "run-last-error" || key == "last-peer-error") {
    if (!(key in first)) {
      first[key] = value
    }
    last[key] = value
  }
}

function print_delta(label, key) {
  start = num(first[key])
  finish = num(last[key])
  printf "%s: %s -> %s (delta %+d)\n", label, start, finish, finish - start
}

function delta(key) {
  return num(last[key]) - num(first[key])
}

function print_rate(label, key) {
  change = delta(key)
  if (rounds > 0) {
    printf "%s-per-round: %.2f\n", label, change / rounds
  }
  if (rounds > 0 && round_deadline > 0) {
    printf "%s-per-hour-estimate: %.2f\n", label, change * 3600 / (rounds * round_deadline)
  }
}

BEGIN {
  rounds = 0
  round_failures = 0
  deadline_count = 0
  peer_error_lines = 0
  progress_reports = 0
  in_analysis = 0
}

/^==> IBD analysis / {
  in_analysis = 1
  next
}

/^==> / {
  in_analysis = 0
}

in_analysis {
  next
}

/^signet-ibd-log-start:/ {
  run_start = substr($0, index($0, ":") + 2)
}

/^data-dir:/ {
  data_dir = substr($0, index($0, ":") + 2)
}

/^network:/ {
  network = substr($0, index($0, ":") + 2)
}

/^round-deadline:/ {
  round_deadline = substr($0, index($0, ":") + 2) + 0
}

/^==> round [0-9]+ start / {
  rounds += 1
  if (first_round_start == "") {
    first_round_start = $0
  }
  last_round_start = $0
}

/^==> round [0-9]+ exit / {
  split($0, parts, " ")
  status = parts[5] + 0
  if (status != 0) {
    round_failures += 1
  }
  last_round_exit = $0
}

/^probe-deadline:/ {
  deadline_count += 1
}

/^last-peer-error:/ {
  if ($0 !~ /last-peer-error: (#f)?$/) {
    peer_error_lines += 1
  }
}

/^(best-height|headers|blocks|validated-blocks|best-block-height|pending-blocks|requested-blocks|failed-blocks|sync-stage|sync-last-error|run-attempts|run-last-result|run-last-error|last-peer-error): / {
  key = $1
  sub(/:$/, "", key)
  value = substr($0, index($0, ":") + 2)
  remember_status(key, value)
}

/^sync-progress:/ {
  progress_reports += 1
  value = substr($0, index($0, ":") + 2)
  if (!("sync-progress" in first)) {
    first["sync-progress"] = value
  }
  last["sync-progress"] = value
}

END {
  print "signet-ibd-analysis"
  if (run_start != "") {
    print "start: " run_start
  }
  if (data_dir != "") {
    print "data-dir: " data_dir
  }
  if (network != "") {
    print "network: " network
  }
  print "rounds-observed: " rounds
  print "round-failures: " round_failures
  print "deadline-events: " deadline_count
  print "peer-error-status-lines: " peer_error_lines
  if (round_deadline > 0) {
    print "round-deadline-seconds: " round_deadline
  }
  if (last_round_exit != "") {
    print "last-round-exit: " last_round_exit
  }
  print ""
  print_delta("headers", "headers")
  print_delta("best-height", "best-height")
  print_delta("blocks", "blocks")
  print_delta("validated-blocks", "validated-blocks")
  print_delta("best-block-height", "best-block-height")
  print_delta("pending-blocks", "pending-blocks")
  print_delta("requested-blocks", "requested-blocks")
  print_delta("failed-blocks", "failed-blocks")
  print ""
  print_rate("headers", "headers")
  print_rate("best-height", "best-height")
  print_rate("blocks", "blocks")
  print_rate("validated-blocks", "validated-blocks")
  print_rate("best-block-height", "best-block-height")
  print ""
  print "final-header-block-lag: " (num(last["best-height"]) - num(last["best-block-height"]))
  print "final-unvalidated-downloaded-blocks: " (num(last["blocks"]) - num(last["validated-blocks"]))
  print ""
  print "final-sync-stage: " last["sync-stage"]
  print "final-sync-progress: " last["sync-progress"]
  print "final-run-attempts: " last["run-attempts"]
  print "final-run-last-result: " last["run-last-result"]
  print "final-sync-last-error: " last["sync-last-error"]
  print "final-run-last-error: " last["run-last-error"]
  print "final-last-peer-error: " last["last-peer-error"]
  print ""
  if (num(last["validated-blocks"]) > num(first["validated-blocks"])) {
    print "assessment: block downloads advanced"
  } else if (num(last["headers"]) > num(first["headers"]) ||
             num(last["best-height"]) > num(first["best-height"])) {
    print "assessment: headers advanced, but validated blocks did not"
  } else {
    print "assessment: no header or validated-block progress observed"
  }
  if (num(last["requested-blocks"]) > 0 && num(last["validated-blocks"]) == num(first["validated-blocks"])) {
    print "warning: requested block queue remained non-empty without validation progress"
  }
  if ((num(last["best-height"]) - num(last["best-block-height"])) > 0 &&
      num(last["pending-blocks"]) == 0 &&
      num(last["requested-blocks"]) == 0) {
    print "warning: headers are ahead of validated blocks, but no block queue is visible"
  }
  if ((num(last["blocks"]) - num(last["validated-blocks"])) > 0) {
    print "warning: downloaded blocks are waiting on validation"
  }
  if (num(last["failed-blocks"]) > num(first["failed-blocks"])) {
    print "warning: failed block count increased"
  }
  if (rounds > 0 && round_failures == rounds) {
    print "warning: every observed round exited non-zero"
  }
}
' "$LOG_FILE"
