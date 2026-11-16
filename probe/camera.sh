#!/usr/bin/env bash
# "Enter your own cube" with the camera, in headless Chrome (probe/shot.mjs),
# as a visitor would use it, a made-up camera in place of a real one:
#
#   probe/camera.sh URL OUT [desktop|phone]
#
# The camera is a canvas: a grey table and a cube's face filling the guide
# square, in a phone's colors (Photo.bend's ph.pal.phone), a little noise
# each frame. The cube is R U (probe/view-own.sh's). The six photos are taken
# as the page asks; before the second, the first face is shown again (the
# page must say it is photo 1 again and keep nothing); after the sixth, the
# net must be the cube and the page must say it read it. A screenshot of the
# camera at photo 1, at the face shown twice, at photo 5, and of the net read.
# Prints PASS or FAIL. A thin shim: the page's own answers.
set -euo pipefail
url=${1%/}
out=$2
dev=${3:-phone}
mkdir -p "$out"
if [ "$dev" = desktop ]; then size=1280x800; env=; else size=390x844; env="DPR=3"; fi

cube=UUUUUUFFFUBBRRRRRRRRRFFDFFDDDBDDBDDBFFDLLLLLLLLLUBBUBB
faces=URFDLB
order=FRBLUD
# photo k: face order[k]'s nine stickers, as Cube.bend lays them out
photo() {
  local f=${order:$1:1}
  local i=${faces%%"$f"*}
  echo "${cube:$((${#i} * 9)):9}"
}

fake="eval:(()=>{const pal={U:[186,192,196],R:[168,32,42],F:[22,148,72],D:[206,198,44],L:[226,98,34],B:[24,62,150]};\
const c=document.createElement('canvas');c.width=640;c.height=480;const g=c.getContext('2d');window.__face='UUUUUUUUU';\
const paint=()=>{g.fillStyle='#8a8478';g.fillRect(0,0,640,480);const side=288,x0=(640-side)/2,y0=(480-side)/2,s=side/3;\
g.fillStyle='#141414';g.fillRect(x0-6,y0-6,side+12,side+12);\
for(let i=0;i<9;i++){const p=pal[__face[i]].map(v=>Math.max(0,Math.min(255,v+Math.round((Math.random()-0.5)*16))));\
g.fillStyle='rgb('+p+')';g.fillRect(x0+(i%3)*s+5,y0+Math.floor(i/3)*s+5,s-10,s-10);}};\
paint();setInterval(paint,60);const st=c.captureStream(20);\
navigator.mediaDevices.getUserMedia=async()=>st;return 'fake camera'})()"
show() { echo "eval:(window.__face='$1','showing $1')"; }
net="[...document.querySelectorAll('#own-net .own-st')].map(b=>b.dataset.face).join('')"
msg="(document.getElementById('own-cam-msg').textContent+document.getElementById('own-msg').textContent)"
state="JSON.stringify({k:document.getElementById('own-k').textContent,hold:document.getElementById('own-hold').textContent,turn:document.getElementById('own-turn').textContent,done:[...document.querySelectorAll('#own-steps .done')].length,msg:$msg})"

steps=(wait:1500 click:#own wait:500 "$fake" click:#own-cam wait:1500 "$(show "$(photo 0)")" wait:800
  shot:"$out/$dev-cam-1.png" "eval:$state" click:#own-shot wait:600
  "$(show "$(photo 0)")" wait:600 click:#own-shot wait:600 "eval:$state" shot:"$out/$dev-cam-twice.png")
for k in 1 2 3 4 5; do
  steps+=("$(show "$(photo $k)")" wait:700)
  [ $k = 4 ] && steps+=(shot:"$out/$dev-cam-5.png")
  steps+=(click:#own-shot wait:600 "eval:$state")
done
steps+=(wait:800 "eval:'NET '+$net" "eval:'MSG '+$msg" shot:"$out/$dev-cam-read.png")

env $env node probe/shot.mjs "$url/" $size "${steps[@]}" >"$out/$dev-camera.log" 2>&1 || true
cat "$out/$dev-camera.log"
ok=1
grep -q "^EVAL \"NET $cube\"" "$out/$dev-camera.log" || { echo "FAIL: the net is not the cube $cube"; ok=0; }
grep -q 'looks like photo 1 again' "$out/$dev-camera.log" || { echo "FAIL: the face shown twice was not caught"; ok=0; }
grep -q '^EVAL "MSG Read from your six photos. Check' "$out/$dev-camera.log" || { echo "FAIL: no word that the photos were read"; ok=0; }
if grep -q -E '^(EXCEPTION|CONSOLE error)' "$out/$dev-camera.log"; then echo "FAIL: the page threw"; ok=0; fi
[ $ok = 1 ] && echo PASS || { echo FAIL; exit 1; }
