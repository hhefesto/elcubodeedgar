#!/usr/bin/env bash
# The 3D view's drag and "Enter your own cube", in headless Chrome
# (probe/shot.mjs), as a visitor would use them:
#
#   probe/view-own.sh URL OUT CHECK
#
# drag: the cube dragged down (its top, U, turned to the front), then
# sideways half a turn (its bottom, D, to the front), then a double click (back to the
# start), a screenshot each, desktop and a 390 px phone (touch);
# own: the panel opened, a corner painted twisted (the reason it cannot be a
# cube, said), then the cube R U painted and solved: the answer checked by
# probe/Check.bend (CHECK). A thin shim: the page's own answers.
set -euo pipefail
url=${1%/}
out=$2
check=$3
mkdir -p "$out"

# a drag on #stage by (dx, dy) in 20 steps; held still before letting go
drag() {
  echo "eval:(()=>{const el=document.getElementById('stage');const r=el.getBoundingClientRect();window.__p={el,x:r.left+r.width/2,y:r.top+r.height/2};const ev=(t,dx,dy)=>el.dispatchEvent(new PointerEvent(t,{clientX:__p.x+dx,clientY:__p.y+dy,pointerId:7,pointerType:'$3',bubbles:true,isPrimary:true}));ev('pointerdown',0,0);for(let i=1;i<=20;i++)ev('pointermove',$1*i/20,$2*i/20);window.__ev=ev;return 'dragged $1 $2'})()"
  echo "wait:300"
  echo "eval:(__ev('pointerup',$1,$2),'let go')"
}

for dev in desktop phone; do
  if [ $dev = desktop ]; then size=1280x800; pt=mouse; env=; else size=390x844; pt=touch; env="DPR=3"; fi
  mapfile -t up < <(drag 0 200 $pt)
  mapfile -t side < <(drag 370 0 $pt)
  env $env node probe/shot.mjs "$url/" $size wait:1500 shot:"$out/$dev-0-start.png" \
    "${up[@]}" wait:400 shot:"$out/$dev-1-top.png" \
    "${side[@]}" wait:400 shot:"$out/$dev-2-bottom.png" \
    "eval:(document.getElementById('stage').dispatchEvent(new MouseEvent('dblclick',{bubbles:true})),'dblclick')" wait:1200 shot:"$out/$dev-3-home.png" \
    >"$out/$dev-drag.log" 2>&1
  cat "$out/$dev-drag.log"
done

status="document.querySelector('.status').textContent"
moves="[...document.querySelectorAll('.strip .tile-m')].map(e=>e.textContent).join(' ')"
pos="document.querySelector('.scr').textContent.replace(/^\\s*position\\s*/i,'').trim()"
idle="until:!document.querySelector('.app').classList.contains('searching')"
paint() {
  echo "eval:(()=>{const want='$1';const cells=[...document.querySelectorAll('#own-net .own-st')];for(let k=0;k<54;k++){if(k%9===4)continue;document.querySelector('#own-pal [data-face=\"'+want[k]+'\"]').click();cells[k].click();}return 'painted '+want})()"
}
twisted=UUUUUUUUFURRRRRRRRFFRFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB
ru=UUUUUUFFFUBBRRRRRRRRRFFDFFDDDBDDBDDBFFDLLLLLLLLLUBBUBB
DPR=3 node probe/shot.mjs "$url/" 390x844 wait:1500 click:#own wait:500 shot:"$out/own-1-panel.png" \
  "$(paint $twisted)" click:#own-go wait:800 "eval:document.getElementById('own-msg').textContent" shot:"$out/own-2-twisted.png" \
  "$(paint $ru)" click:#own-go wait:4000 "eval:location.hash + ' | ' + $status" "$idle" \
  "eval:$status" shot:"$out/own-3-solved.png" "eval:'POS ' + $pos + ' | ' + $moves" \
  >"$out/own.log" 2>&1
cat "$out/own.log"
line=$(grep '^EVAL "POS' "$out/own.log" | tail -1 | sed 's/^EVAL "POS //; s/"$//')
p=${line%% | *}
a=${line##* | }
nums() {
  local m f t ns=()
  for m in "$@"; do
    case ${m:0:1} in U) f=0 ;; R) f=1 ;; F) f=2 ;; D) f=3 ;; L) f=4 ;; B) f=5 ;; *) return 1 ;; esac
    case ${m:1} in "") t=0 ;; 2) t=1 ;; "'") t=2 ;; *) return 1 ;; esac
    ns+=($((f * 3 + t)))
  done
  (IFS=.; echo "${ns[*]}")
}
echo "position: $p"
echo "answer:   $a"
# shellcheck disable=SC2086
"$check" "$(nums $p)" "$(nums $a)"
