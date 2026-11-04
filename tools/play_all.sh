#!/bin/sh
# The suite and every headless playthrough at the fixed frame rate they need, one line each, then the failed checks.
# Run before merging a branch (play_relay alone takes over 10 minutes):
#   sh tools/play_all.sh                    # all of them
#   sh tools/play_all.sh suite play_harbour # just these
# Exits 1 when anything failed. Full output per run in $TMPDIR/play_all/<name>.log.
cd "$(dirname "$0")/.." || exit 2
logs="${TMPDIR:-/tmp}/play_all"
mkdir -p "$logs"
runs="${*:-suite play_harbour play_annex play_core play_relay}"
bad=0
for r in $runs; do
  start=$(date +%s)
  if [ "$r" = suite ]; then
    godot --headless --path . tools/run_tests.tscn > "$logs/$r.log" 2>&1
  else
    godot --headless --fixed-fps 60 --path . "tools/$r.tscn" > "$logs/$r.log" 2>&1
  fi
  code=$?
  verdict=PASS
  [ $code -ne 0 ] && { verdict=FAIL; bad=1; }
  printf '%s  %-13s %4ss  %s\n' "$verdict" "$r" "$(( $(date +%s) - start ))" \
    "$(grep -E '^passed [0-9]+|: [0-9]+ failed' "$logs/$r.log" | tail -1)"
  grep -E '^FAIL' "$logs/$r.log" | sed 's/^/      /'
done
exit $bad
