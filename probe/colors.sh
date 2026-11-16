#!/usr/bin/env bash
# Your cube's colors (web/colors.js, Scheme.bend), in headless Chrome
# (probe/shot.mjs), as a visitor would use them:
#
#   probe/colors.sh URL OUT [desktop|phone]
#
# The picker: the row under "Enter your own cube" opens it; Japanese picked,
# the page's colors and words are the Japanese ones (the panel's "then
# yellow" is "then blue"), and kept on a reload; a face's color picked of
# one's own (the right face pink: a scheme of one's own).
# The 3D cube: in the Japanese colors too (#stage's data-colors, U R F D L
# B), and, the picker closed, turned to show the two faces that changed
# (blue underneath, yellow at the back: data-look DB), then back; on a
# reload, in them from the start, with no turn.
# The camera: a cube with the Japanese colors, photographed while the page
# shows the Standard ones, as the page asks (turning as the arrow shows); after
# the fourth photo the page must offer the Japanese colors, and once they are
# taken, the six photos must read the cube.
# Screenshots of each. Prints PASS or FAIL. A thin shim: the page's own answers.
set -euo pipefail
url=${1%/}
out=$2
dev=${3:-phone}
mkdir -p "$out"
if [ "$dev" = desktop ]; then size=1280x800; env=; else size=390x844; env="DPR=3"; fi

root="getComputedStyle(document.documentElement)"
state="JSON.stringify({key:document.documentElement.dataset.scheme,D:$root.getPropertyValue('--D').trim(),B:$root.getPropertyValue('--B').trim(),name:$root.getPropertyValue('--sch-name').trim()})"
intro="document.getElementById('own-intro').textContent"
cube3="JSON.stringify(document.getElementById('stage').dataset)"

steps=(wait:1500 shot:"$out/$dev-page.png" click:#colors wait:600 shot:"$out/$dev-picker.png"
  "click:#sch-list [data-k=\"2\"]" wait:400 "eval:'PICKED '+$state" shot:"$out/$dev-picker-jp.png"
  "click:#sch-dlg button[value=close]" wait:1000 "eval:'CUBE '+$cube3" shot:"$out/$dev-page-jp.png" wait:2600 shot:"$out/$dev-page-jp-back.png"
  click:#own wait:500 "eval:'INTRO '+$intro" shot:"$out/$dev-own-jp.png"
  "click:#own-dlg button[value=close]" wait:300
  "eval:(location.reload(),'reload')" wait:2500 "eval:'KEPT '+$state" "eval:'CUBEKEPT '+$cube3" "eval:'HOWTO '+document.querySelector('.faces').textContent.replace(/\\s+/g,' ')"
  click:#colors wait:500 "click:#sch-own summary" wait:300 "click:#sch-faces [data-f=\"1\"][data-c=\"6\"]" wait:400
  "eval:'OWN '+$state" shot:"$out/$dev-picker-own.png"
  "click:#sch-list [data-k=\"5\"]" wait:400 "eval:'SPEED '+$state" shot:"$out/$dev-picker-speed.png"
  "click:#sch-dlg button[value=close]" wait:1000 "eval:'CUBESPEED '+$cube3" wait:2600 shot:"$out/$dev-page-speed.png"
  "eval:(localStorage.removeItem('elcubo.colors'),localStorage.setItem('elcubo.colours',JSON.stringify({key:'2',name:'Japanese',names:['white','red','green','blue','orange','yellow'],css:null,inks:null})),location.reload(),'reload')"
  wait:2500 "eval:'MOVED '+$state+' '+(localStorage.getItem('elcubo.colours')===null)")
env $env node probe/shot.mjs "$url/" $size "${steps[@]}" >"$out/$dev-colors.log" 2>&1 || true
cat "$out/$dev-colors.log"

# the camera: a Japanese cube, the page on Standard (a fresh profile)
cube=UUUUUUFFFUBBRRRRRRRRRFFDFFDDDBDDBDDBFFDLLLLLLLLLUBBUBB
faces=URFDLB
order=FRBLUD
photo() {
  local f=${order:$1:1}
  local i=${faces%%"$f"*}
  echo "${cube:$((${#i} * 9)):9}"
}
fake="eval:(()=>{const pal={U:[186,192,196],R:[168,32,42],F:[22,148,72],D:[24,62,150],L:[226,98,34],B:[206,198,44]};\
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
fit="JSON.stringify({shown:!document.getElementById('own-fit').hidden,text:document.getElementById('own-fit-t').textContent,yes:document.getElementById('own-fit-yes').textContent,shot:document.getElementById('own-shot').disabled})"
hold="document.getElementById('own-hold').textContent"

steps=(wait:1500 click:#own wait:500 "$fake" click:#own-cam wait:1500)
for k in 0 1 2 3; do
  steps+=("$(show "$(photo $k)")" wait:700 "eval:'HOLD $k '+$hold" click:#own-shot wait:700)
done
steps+=("eval:'FIT '+$fit" shot:"$out/$dev-cam-fit.png" click:#own-fit-yes wait:600 "eval:'AFTER '+$state" "eval:'HOLD 4 '+$hold" shot:"$out/$dev-cam-after.png")
for k in 4 5; do
  steps+=("$(show "$(photo $k)")" wait:700 click:#own-shot wait:700)
done
steps+=(wait:800 "eval:'NET '+$net" "eval:'MSG '+$msg" shot:"$out/$dev-cam-read.png")
env $env node probe/shot.mjs "$url/" $size "${steps[@]}" >"$out/$dev-colors-cam.log" 2>&1 || true
cat "$out/$dev-colors-cam.log"

# a mirrored cube (orange on the right, red on the left), the offer declined:
# the page stays Standard, the photos go on, and the six still read the cube
mirror=${fake/R:\[168,32,42\]/R:[226,98,34]}
mirror=${mirror/L:\[226,98,34\]/L:[168,32,42]}
mirror=${mirror/D:\[24,62,150\]/D:[206,198,44]}
mirror=${mirror/B:\[206,198,44\]/B:[24,62,150]}
steps=(wait:1500 click:#own wait:500 "$mirror" click:#own-cam wait:1500)
for k in 0 1 2 3; do
  steps+=("$(show "$(photo $k)")" wait:700 click:#own-shot wait:700)
done
steps+=("eval:'FIT '+$fit" click:#own-fit-no wait:600 "eval:'AFTER '+$state" "eval:'HOLD 4 '+$hold")
for k in 4 5; do
  steps+=("$(show "$(photo $k)")" wait:700 click:#own-shot wait:700)
done
steps+=(wait:800 "eval:'NET '+$net" "eval:'MSG '+$msg")
env $env node probe/shot.mjs "$url/" $size "${steps[@]}" >"$out/$dev-colors-keep.log" 2>&1 || true
cat "$out/$dev-colors-keep.log"

ok=1
log=$out/$dev-colors.log
cam=$out/$dev-colors-cam.log
grep -q '^EVAL "PICKED {\\"key\\":\\"2\\",\\"D\\":\\"rgb(11,79,179)\\"' "$log" || { echo "FAIL: Japanese picked, the bottom is not blue"; ok=0; }
grep -q '^EVAL "INTRO .*red and yellow, then blue' "$log" || { echo "FAIL: the panel does not say the Japanese colors"; ok=0; }
grep -q '^EVAL "KEPT {\\"key\\":\\"2\\"' "$log" || { echo "FAIL: Japanese not kept on a reload"; ok=0; }
grep -qxF 'EVAL "CUBE {\"colors\":\"#f4f0e6 #c41230 #00a04e #0b4fb3 #ff6a13 #ffd31a\",\"look\":\"DB\",\"lookTurn\":\"true\"}"' "$log" || { echo "FAIL: Japanese picked, the 3D cube is not in them or did not turn to show them"; ok=0; }
grep -qxF 'EVAL "CUBEKEPT {\"colors\":\"#f4f0e6 #c41230 #00a04e #0b4fb3 #ff6a13 #ffd31a\"}"' "$log" || { echo "FAIL: on a reload, the 3D cube is not in the kept colors (or turned)"; ok=0; }
grep -q '^EVAL "HOWTO .*the bottom: blue' "$log" || { echo "FAIL: the moves explained do not say the Japanese colors"; ok=0; }
grep -q '^EVAL "OWN {\\"key\\":\\"064531\\"' "$log" || { echo "FAIL: the right face pink is not a scheme of one's own"; ok=0; }
grep -q '^EVAL "SPEED {\\"key\\":\\"5\\",\\"D\\":\\"rgb(252,211,4)\\",\\"B\\":\\"rgb(10,145,212)\\"' "$log" || { echo "FAIL: Rubik's Speed picked, the page is not in its colors"; ok=0; }
grep -qF 'EVAL "CUBESPEED {\"colors\":\"#edeef2 #f2505e #28cd46 #fcd304 #fd9150 #0a91d4\"' "$log" || { echo "FAIL: Rubik's Speed picked, the 3D cube is not in its colors"; ok=0; }
grep -q '^EVAL "MOVED {\\"key\\":\\"2\\",\\"D\\":\\"rgb(11,79,179)\\".* true"$' "$log" || { echo "FAIL: a scheme kept under the old key (elcubo.colours) is not kept"; ok=0; }
grep -q '^EVAL "FIT {\\"shown\\":true,\\"text\\":\\"Your cube looks like it has the Japanese colors' "$cam" || { echo "FAIL: four photos of a Japanese cube, no offer"; ok=0; }
grep -q '^EVAL "AFTER {\\"key\\":\\"2\\"' "$cam" || { echo "FAIL: the offer taken, the page is not Japanese"; ok=0; }
grep -q '^EVAL "HOLD 4 The white centre facing you, the yellow centre on top' "$cam" || { echo "FAIL: photo 5 not said in the Japanese colors"; ok=0; }
grep -q "^EVAL \"NET $cube\"" "$cam" || { echo "FAIL: the net is not the cube $cube"; ok=0; }
grep -q '^EVAL "MSG Read from your six photos. Check' "$cam" || { echo "FAIL: no word that the photos were read"; ok=0; }
keep=$out/$dev-colors-keep.log
grep -q '^EVAL "FIT {\\"shown\\":true,\\"text\\":\\"Your cube looks like it has the Mirrored colors' "$keep" || { echo "FAIL: four photos of a mirrored cube, no offer"; ok=0; }
grep -q '^EVAL "AFTER {\\"key\\":\\"0\\"' "$keep" || { echo "FAIL: the offer declined, the page is not Standard"; ok=0; }
grep -q '^EVAL "HOLD 4 The white centre facing you, the blue centre on top' "$keep" || { echo "FAIL: declined, photo 5 not asked for"; ok=0; }
grep -q "^EVAL \"NET $cube\"" "$keep" || { echo "FAIL: declined, the net is not the cube $cube"; ok=0; }
if grep -q -i 'exception\|uncaught' "$log" "$cam" "$keep"; then echo "FAIL: the page threw"; ok=0; fi
[ $ok = 1 ] && echo PASS || echo FAIL
