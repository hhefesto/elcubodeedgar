#!/usr/bin/env bash
# The device's solver timed with 1, 2, 4, 8 workers in headless Chrome
# (probe/bench.html on BASE, a server like probe/site-test.sh's), each answer
# checked by probe/Check.bend ($CHECK) apart from the solver's own check.
# A thin shim: the timing is bench.html's, the checking Check.bend's.
#
#   probe/bench.sh BASE CHECK OUTDIR CUBE,CUBE,..  [WORKERS...]
set -u
BASE=$1 CHECK=$2 OUT=$3 CUBES=$4
shift 4
mkdir -p "$OUT"
for n in "${@:-8 4 2 1}"; do
  EVAL_MAX=1000000 node probe/shot.mjs "$BASE/bench.html?workers=$n&cubes=$CUBES" 1280x800 'until:document.title === "done"' \
    'eval:document.getElementById("out").textContent' > "$OUT/raw-$n.txt" 2>&1
  node -e 'const l = require("fs").readFileSync(0, "utf8").split("\n").find((x) => x.startsWith("EVAL ")); process.stdout.write(JSON.parse(l.slice(5)))' < "$OUT/raw-$n.txt" > "$OUT/bench-$n.json"
  # every answer checked
  node -e 'for (const c of JSON.parse(require("fs").readFileSync(0, "utf8")).cubes) console.log(c.cube, c.final, c.moves || "-")' < "$OUT/bench-$n.json" |
    while read -r cube final moves; do
      [ "$moves" = - ] && moves=""
      echo "$n workers: $cube ($final): $($CHECK "$cube" "$moves")"
    done > "$OUT/check-$n.txt"
  cat "$OUT/check-$n.txt"
done
