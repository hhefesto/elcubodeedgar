#!/usr/bin/env bash
# The solver's tests, as a visitor sees it: a thin shim around curl. The
# checking is Bend's: probe/Check.bend (built as $CHECK) says whether an
# answer solves its scramble, apart from the solver's own check.
#
#   probe/solve-tests.sh BASE CHECK
#
# BASE: the solve URL up to its query, "http://127.0.0.1:28095/solve" (the
# solver) or "https://elcubodeedgar.hhefesto.dev/api/solve" (the site).
# Each test uses its own visitor name, so it cancels nothing of anyone's.
set -u
BASE=$1
CHECK=$2
pass=0
fail=0
run="t$(date +%s)"

ask() { curl -s -m 70 "$BASE?m=$2&v=$run-$1"; }

# ask until the answer is final (not "working" or "queued"), as the page does;
# prints: seconds, asks, the final answer's lines joined by |
poll() {
  local v=$1 m=$2 t0 n=0 body w
  t0=$(date +%s.%N)
  while :; do
    body=$(ask "$v" "$m")
    n=$((n + 1))
    w=$(printf '%s\n' "$body" | sed -n 1p)
    [ "$w" = working ] || [ "$w" = queued ] || break
  done
  printf '%s %s %s\n' "$(awk -v a="$t0" -v b="$(date +%s.%N)" 'BEGIN { printf "%.1f", b - a }')" "$n" "$(printf '%s' "$body" | tr '\n' '|')"
}

ok() { pass=$((pass + 1)); echo "PASS $*"; }
no() { fail=$((fail + 1)); echo "FAIL $*"; }

# the final answer for scramble m (k moves; d its known distance, or -):
# it must solve m, be at most k moves, d exactly if d is known and the
# answer says it is the shortest, and say "shortest" only of a finished search
final() {
  local name=$1 m=$2 k=$3 d=$4 out secs asks ans w sol c len
  out=$(poll "$name" "$m")
  read -r secs asks ans <<<"$out"
  w=${ans%%|*}
  case "$w" in
    short)
      sol=$(echo "$ans" | cut -d'|' -f6)
      c=$($CHECK "$m" "$sol")
      len=${c#solves }
      if [ "${c%% *}" = solves ] && [ "$len" -le "$k" ]; then
        ok "$name: a short way, $len moves (not proven shortest; at least $(echo "$ans" | cut -d'|' -f5)), ${secs} s, $asks asks"
      else no "$name: short answer '$ans' ($c)"; fi ;;
    busy|cancelled|none|late|down|queued|working)
      no "$name: '$ans' after ${secs} s" ;;
    *)
      sol=$w
      c=$($CHECK "$m" "$sol")
      len=${c#solves }
      if [ "${c%% *}" != solves ]; then no "$name: '$ans' does not solve it";
      elif [ "$len" -gt "$k" ]; then no "$name: $len moves, longer than the scramble's $k";
      elif [ "$d" != - ] && [ "$len" != "$d" ]; then no "$name: $len moves as the shortest, but its distance is $d";
      else ok "$name: shortest, $len moves, ${secs} s, $asks asks"; fi ;;
  esac
}

SF=0.4.6.15.3.16.3.1.12.16.3.2.11.4.6.5.12.16.1.7
# known distances: a solved cube; one move; the 6-move checkerboard (U2 D2 F2 B2 L2 R2)
final solved "" 0 0
final one 3 1 1
final checker 1.10.7.16.13.4 6 6
final four 3.0.6.12 4 4
final twelve 3.0.6.12.9.15.1.4.7.10.13.16 12 12
final sixteen 3.0.6.9.12.15.4.1.8.11.13.17.5.2.7.10 16 16
final hand23 6.2.16.0.6.12.11.7.4.0.16.2.3.8.3.8.9.12.17.7.4.14.15 23 -
final hand18 6.10.13.16.12.9.8.4.7.9.6.5.10.13.6.10.14.11 18 -
final superflip $SF 20 20

# the same cube asked twice at once: one search, both askers get its answer
H=0.15.5.17.14.7.11.12.8.13.2.10.7.9.5.12.6.17.8.12.4.9.3.8.10.7.11.2.12.0.17.3.16.7.9
a=$(mktemp) b=$(mktemp)
(poll twice "$H" > "$a") & sleep 2; (poll twice "$H" > "$b") & wait
if [ "$(cut -d' ' -f3- "$a")" = "$(cut -d' ' -f3- "$b")" ]; then ok "twice: the same answer to both: $(cut -c1-80 "$a")"
else no "twice: $(cat "$a") / $(cat "$b")"; fi

# a new cube mid-solve (before the old one's first word, at 2 s): the old one's
# asker hears "cancelled", the new one is solved
(ask mid "$H" > "$a") & sleep 1; final mid 3.0.6.12 4 4; wait
if [ "$(sed -n 1p "$a")" = cancelled ]; then ok "mid: the old cube's ask was cancelled"; else no "mid: the old ask got '$(tr '\n' '|' < "$a")'"; fi

# asked again after its answer: the answer kept, at once
out=$(poll twelve 3.0.6.12.9.15.1.4.7.10.13.16)
if [ "$(echo "$out" | cut -d' ' -f1 | cut -d. -f1)" -le 1 ]; then ok "kept: $out"; else no "kept: $out"; fi

rm -f "$a" "$b"
echo "passed $pass, failed $fail"
