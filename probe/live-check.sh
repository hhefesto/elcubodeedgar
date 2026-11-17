#!/usr/bin/env bash
# The site checked as a visitor sees it, in headless Chrome (probe/shot.mjs):
#
#   probe/live-check.sh URL OUT CHECK [long]
#
# desktop (1280x800): a random scramble solved on the device, the tables'
# download sizes; phone (390x844, DPR 3, touch, an iPhone's user agent): a
# 7-move hand scramble solved, Play, How to, buttons under 44 px; with "long",
# the superflip from a #m= link: its short way, then the hand-off after 240 s.
# Each answer is checked by probe/Check.bend (CHECK, run/bt/check).
# A thin shim: the page's own answers, Check.bend's checking.
set -euo pipefail
url=${1%/}
out=$2
check=$3
long=${4:-}
mkdir -p "$out"

# wire form ("3.10.17") of moves like "U R2 F'"
nums() {
  local m f t ns=()
  for m in "$@"; do
    case ${m:0:1} in U) f=0 ;; R) f=1 ;; F) f=2 ;; D) f=3 ;; L) f=4 ;; B) f=5 ;; *) return 1 ;; esac
    case ${m:1} in "") t=0 ;; 2) t=1 ;; "'") t=2 ;; *) return 1 ;; esac
    ns+=($((f * 3 + t)))
  done
  (IFS=.; echo "${ns[*]}")
}

# the "pos | answer" line an eval printed, checked
checked() {
  local line pos ans
  line=$(grep '^EVAL "POS' "$1" | tail -1 | sed 's/^EVAL "POS //; s/"$//')
  pos=${line%% | *}
  ans=${line##* | }
  echo "position: $pos"
  echo "answer:   $ans"
  # shellcheck disable=SC2086
  "$check" "$(nums $pos)" "$(nums $ans)"
}

status="document.querySelector('.status').textContent"
facts="document.querySelector('.facts').textContent"
moves="[...document.querySelectorAll('.strip .tile-m')].map(e=>e.textContent).join(' ')"
pos="document.querySelector('.scr').textContent.replace(/^\\s*position\\s*/i,'').trim()"
idle="until:!document.querySelector('.app').classList.contains('searching')"

node probe/shot.mjs "$url/" 1280x800 wait:1500 \
  "eval:crossOriginIsolated + ' cores ' + navigator.hardwareConcurrency" \
  click:#scramble wait:2500 "eval:$status" "$idle" \
  "eval:$status + ' | ' + $facts" shot:"$out/desktop-1-scramble-solved.png" \
  "eval:'POS ' + $pos + ' | ' + $moves" \
  "eval:JSON.stringify(performance.getEntriesByType('resource').filter(e=>/\\/t\\/|dev.mjs|tables.json|chunk/.test(e.name)).map(e=>[e.name.split('/').pop(), e.transferSize, e.decodedBodySize, Math.round(e.duration)]))" \
  >"$out/desktop.log" 2>&1
cat "$out/desktop.log"
checked "$out/desktop.log"

DPR=3 node probe/shot.mjs "$url/" 390x844 wait:1500 shot:"$out/iphone-1-start.png" \
  "eval:crossOriginIsolated + ' ' + innerWidth + 'x' + innerHeight + ' scrollW ' + document.documentElement.scrollWidth" \
  click:#t3 wait:350 click:#t0 wait:350 click:#t5 wait:350 click:#t2 wait:350 click:#t6 wait:350 \
  click:#t11 wait:350 click:#t16 wait:700 click:#solve wait:1200 "eval:$status" "$idle" \
  "eval:$status + ' | ' + $facts" shot:"$out/iphone-2-hand-solved.png" \
  "eval:'POS ' + $pos + ' | ' + $moves" \
  click:#play wait:6500 "eval:$status" click:#howto wait:800 shot:"$out/iphone-3-howto.png" \
  "eval:'small buttons ' + JSON.stringify([...document.querySelectorAll('button')].filter(b=>b.offsetParent).map(b=>{const r=b.getBoundingClientRect(); return [b.id||b.textContent.trim().slice(0,10), Math.round(r.width), Math.round(r.height)]}).filter(x=>x[1]<44||x[2]<44))" \
  >"$out/phone.log" 2>&1
cat "$out/phone.log"
checked "$out/phone.log"

if [ "$long" = long ]; then
  DPR=3 node probe/shot.mjs "$url/#m=0.4.6.15.3.16.3.1.12.16.3.2.11.4.6.5.12.16.1.7" 390x844 wait:6000 \
    "eval:$status" shot:"$out/iphone-4-link-working.png" "$idle" \
    "eval:$status + ' | ' + $facts + ' | ' + document.getElementById('handoff-link')?.getAttribute('href')" \
    "eval:'POS ' + $pos + ' | ' + $moves" \
    "eval:scrollTo(0, document.querySelector('.handoff').getBoundingClientRect().top + scrollY - 330); 1" \
    wait:600 shot:"$out/iphone-5-handoff.png" >"$out/link.log" 2>&1
  cat "$out/link.log"
  checked "$out/link.log"
fi
