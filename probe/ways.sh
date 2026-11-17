#!/usr/bin/env bash
# "Solve it your way" (App.bend's ways.panel, Ways.bend in web/ways-worker.js),
# in headless Chrome (probe/shot.mjs), as a visitor would use it:
#
#   probe/ways.sh URL OUT [desktop|phone]
#
# A scramble (once its turns are over): the four ways' moves come (the fewest moves, then F2L (CFOP), F2L
# simplified, the beginner's: each more than the one before, as a rule, and
# the fewest the fewest); F2L (CFOP) picked, the strip is its steps (Cross,
# four F2L pairs, OLL, PLL), Next step makes its first move, Play the rest,
# and the page says it is solved that way; the beginner's picked during it
# takes its place once the turn under way is over; back to the fewest moves.
# Screenshots of each. Prints PASS or FAIL. A thin shim: the page's own answers.
set -euo pipefail
url=${1%/}
out=$2
dev=${3:-phone}
mkdir -p "$out"
if [ "$dev" = desktop ]; then size=1280x900; env=; else size=390x844; env="DPR=3"; fi

counts="JSON.stringify([0,1,2,3].map(k=>document.querySelector('#way'+k+' .way-n').firstChild.textContent))"
status="document.querySelector('.status').textContent"
steps="JSON.stringify([...document.querySelectorAll('.step-h .step-l')].map(e=>e.textContent))"
picked="JSON.stringify([...document.querySelectorAll('.way')].map(e=>e.getAttribute('aria-checked')))"
see="document.querySelector('.ways').scrollIntoView({block:'start'})"
ready="/^[0-9]+\$/.test(document.querySelector('#way3 .way-n').firstChild.textContent)&&/^[0-9]+\$/.test(document.querySelector('#way0 .way-n').firstChild.textContent)&&!document.querySelector('.app').classList.contains('busy')"

steps_=(wait:1500 "eval:$see" shot:"$out/$dev-before.png"
  click:#scramble "until:$ready" wait:800
  "eval:'COUNTS '+$counts" "eval:$see" shot:"$out/$dev-ways.png"
  click:#way1 wait:500 "eval:'PICKED '+$picked" "eval:'STATUS '+$status" "eval:'STEPS '+$steps" shot:"$out/$dev-cfop.png"
  click:#next wait:900 "eval:'NEXT '+$status" "eval:'NOW '+document.querySelector('.step-h.now .step-l')?.textContent"
  click:#play "until:/^Solved/.test($status)" wait:300 "eval:'SOLVED '+$status" shot:"$out/$dev-cfop-done.png"
  click:#way3 wait:500 "eval:'BEGIN '+$status" "eval:'BSTEPS '+$steps" click:#next wait:200 click:#way2 wait:900
  "eval:'PEND '+$picked+' '+$status" shot:"$out/$dev-simple.png"
  click:#way0 wait:500 "eval:'OURS '+$picked+' '+$status" shot:"$out/$dev-ours.png")

log=$out/$dev-ways.log
env $env node probe/shot.mjs "$url/" "$size" "${steps_[@]}" | tee "$log"

fail=0
check() { if grep -q -- "$2" "$log"; then echo "ok: $1"; else echo "FAIL: $1"; fail=1; fi; }
counts=$(grep -o 'COUNTS \[[^]]*\]' "$log" | head -1 | grep -o '[0-9]\+' | tr '\n' ' ')
read -r c0 c1 c2 c3 <<< "$counts"
if [ -n "${c3:-}" ] && [ "$c0" -le "$c1" ] && [ "$c0" -le "$c2" ] && [ "$c0" -le "$c3" ] && [ "$c1" -le "$c3" ]; then echo "ok: four ways ($counts)"; else echo "FAIL: four ways ($counts)"; fail=1; fi
check "F2L (CFOP) picked" 'PICKED \[\\"false\\",\\"true\\",\\"false\\",\\"false\\"\]'
check "its steps" 'STEPS \[\\"Cross\\",\\"F2L: the'
check "its PLL" 'PLL\\"\]'
check "Next step: step 1" 'NEXT Step 1 of 7: Cross'
check "Play: solved that way" 'SOLVED Solved the F2L (CFOP) way, in'
check "the beginner's" 'BEGIN Beginner.s: [0-9]* moves, in 16 steps'
check "a pick during a turn waits for it" 'PEND \[\\"false\\",\\"false\\",\\"true\\",\\"false\\"\] F2L, simplified: [0-9]* moves, in 9 steps'
check "back to the fewest" 'OURS \[\\"true\\",\\"false\\",\\"false\\",\\"false\\"\]'
if grep -q 'EXCEPTION' "$log"; then echo "FAIL: a page exception"; fail=1; fi
if [ $fail = 0 ]; then echo PASS; else echo FAIL; fi
