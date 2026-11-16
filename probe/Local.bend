import Base
import ../Cube.bend as C
import ../Coord.bend as K
import ../Search.bend as S
import ../Par.bend as P

# The solver on the visitor's device: Search.bend's IDA* over Coord.bend's
# three tables (the corners; two sets of six edges), compiled to JavaScript
# (`bend probe/Local.bend -o local.mjs`, served as local.js) and called from
# a Web Worker (probe/worker.js), which holds the tables (Coord.bend's 2^26
# words, fetched once) and asks for one bound after another, telling the page
# between them.
# So a long search never holds the page, and the worker can be stopped at
# any time.
#
# A probe for now: the page does not use it yet (probe/device.html runs it).
#
# A cube is the moves that make it from solved, in Cube.bend's wire form
# ("3.10.17").
#
# Every def is prefixed `lc.`.

def lc.moves(+s: String) -> List<&2, U32>:
  Maybe.default(&2, List<&2, U32>, C.cube.read(s), Nil{})

def lc.coords(+s: String) -> K.Coords:
  K.co.of(C.cube.apply(lc.moves(s), C.cube.solved()))

# the cube's distance bound: the first bound to search (0 if it is solved)
def lc.start(t: Array<U32>, +s: String) -> Array<U32> & U32:
  +c = lc.coords(s)
  S.sr.h(t, P.pl.cp(c), P.pl.tw(c), P.pl.ea(c), P.pl.eb(c))

# a search's answer, three lines: "ok" and the moves (checked here, by
# Cube.bend: the scramble then them leaves the cube solved), or "WRONG" if
# they do not, or "none" (no solution of that length); then the nodes
def lc.say(+ms: List<&2, U32>, r: Array<U32> & S.Res) -> Array<U32> & String:
  (t, res) = r
  match res:
    case S.Res{Some{+sol}, n}:
      +ok = C.cube.is_solved(C.cube.apply(sol, C.cube.apply(ms, C.cube.solved())))
      (t, Bool.pick(String, ok, "ok", "WRONG") ++ "\n" ++ C.cube.nums(sol) ++ "\n" ++ U32.show(n))
    case S.Res{None{}, n}:
      (t, "none\n\n" ++ U32.show(n))

def lc.bound.go(zero: Bool, t: Array<U32>, +s: String, +b: U32) -> Array<U32> & String:
  match zero:
    case True{}:
      (t, "ok\n\n0")
    case False{}:
      +c = lc.coords(s)
      lc.say(lc.moves(s), S.sr.below(U32.to_nat(b), t, P.pl.cp(c), P.pl.tw(c), P.pl.ea(c), P.pl.eb(c), 6, Nil{}))

# every sequence of b moves from the cube (a shortest solution if its
# bounds below b had none: Search.bend); bound 0 is the solved cube's
def lc.bound(t: Array<U32>, +s: String, +b: U32) -> Array<U32> & String:
  lc.bound.go(U32.is_zero(b), t, s, b)
