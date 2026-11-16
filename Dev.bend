import Base
import ./Cube.bend as C
import ./Coord.bend as K
import ./Search.bend as S
import ./Sym.bend as Y
import ./Guard.bend as Gd
import ./Lite.bend as L

# The solver on the visitor's device: what a Web Worker calls (web/solver.js
# gives each worker one of these calls at a time; web/Sched.bend decides
# which). Every call is independent of every other: a bound's subtrees, one
# per three-move prefix, can run on as many cores as there are, here as
# Web Workers, natively as Bend's parallel calls.
#
# The tables: one array of lt.end() words, shared by the workers (a
# SharedArrayBuffer): Coord.bend's move tables (made here, dv.build.*, the
# edges' split over the workers), Coord.bend's three distance tables (Korf's:
# the corners, two sets of six edges) and Lite.bend's (both downloaded once,
# made by DevTables.bend).
#
# A cube is its stickers, a facelet string ("UUUUUUUUURRR..."), read by
# Guard.bend: so a cube from the camera or the paint is solved as one from
# moves is. Every answer is checked here by Cube.bend (the scramble then the
# answer leaves the cube solved), and again by the page.
#
# Every def is prefixed `dv.`.

# A cube to solve: it and its coordinates; or why its stickers are no cube
type Root is Data:
  Root{+c: C.Cube, +k: K.Coords}
  NoRoot{+why: String}

def dv.root.of(+r: Gd.Read) -> Root:
  match r:
    case Gd.Good{+c}:
      Root{c, K.co.of(c)}
    case Gd.Bad{+w}:
      NoRoot{w}

def dv.root(s: String) -> Root:
  dv.root.of(Gd.gd.read(s))

def dv.ok(+r: Root) -> Bool:
  match r:
    case Root{c, k}:
      True{}
    case NoRoot{w}:
      False{}

def dv.why(+r: Root) -> String:
  match r:
    case Root{c, k}:
      ""
    case NoRoot{+w}:
      w

def dv.cp(+k: K.Coords) -> U32:
  match k:
    case K.Coords{+cp, tw, a, fa, b, fb}:
      cp

def dv.tw(+k: K.Coords) -> U32:
  match k:
    case K.Coords{cp, +tw, a, fa, b, fb}:
      tw

def dv.ea(+k: K.Coords) -> U32:
  match k:
    case K.Coords{cp, tw, +a, +fa, b, fb}:
      U32.add(U32.shln(a, 6n), fa)

def dv.eb(+k: K.Coords) -> U32:
  match k:
    case K.Coords{cp, tw, a, fa, +b, +fb}:
      U32.add(U32.shln(b, 6n), fb)

# The tables a device makes
# -------------------------

# the corners' move tables (cp's, tw's)
def dv.build.cptw(t: Array<U32>) -> Array<U32>:
  +ms = K.co.moves()
  K.co.fill.tw(2187n, K.co.fill.cp(40320n, t, 0, ms), 0, ms)

# rows i .. i + n of the edges' move table (665280 rows in all)
def dv.build.e(t: Array<U32>, +i: U32, +n: U32) -> Array<U32>:
  K.co.fill.e(U32.to_nat(n), t, i, K.co.emoves())

def dv.len() -> U32:
  L.lt.end()

# The shortest search (Korf's: Search.bend's IDA*)
# ------------------------------------------------

def dv.h.of(r: Array<U32> & U32) -> Array<U32> & U32:
  (t, +h) = r
  (t, h)

# the cube's bound: every solution has at least that many moves
def dv.h(t: Array<U32>, +r: Root) -> Array<U32> & U32:
  match r:
    case Root{c, +k}:
      dv.h.of(S.sr.h(t, dv.cp(k), dv.tw(k), dv.ea(k), dv.eb(k)))
    case NoRoot{w}:
      (t, 99)

def dv.len.of(xs: List<&2, U32>) -> U32:
  match xs:
    case Nil{}:
      0
    case Con{x, t}:
      U32.add(dv.len.of(t), 1)

# an answer, three lines: "ok" (it solves the cube c) or "WRONG", and the
# moves; or "none" (none of that length) and no moves; then the nodes
def dv.say(+c: C.Cube, r: Array<U32> & S.Res) -> Array<U32> & String:
  (t, res) = r
  match res:
    case S.Res{Some{+sol}, +n}:
      +ok = C.cube.is_solved(C.cube.apply(sol, c))
      (t, Bool.pick(String, ok, "ok", "WRONG") ++ "\n" ++ C.cube.nums(sol) ++ "\n" ++ U32.show(n))
    case S.Res{None{}, +n}:
      (t, "none\n\n" ++ U32.show(n))

# every sequence of b moves from the cube, on this core: a solution is a
# shortest one if every smaller bound had none
def dv.bound(t: Array<U32>, +r: Root, +b: U32) -> Array<U32> & String:
  match r:
    case Root{+c, +k}:
      dv.say(c, S.sr.below(U32.to_nat(b), t, dv.cp(k), dv.tw(k), dv.ea(k), dv.eb(k), 6, Nil{}))
    case NoRoot{w}:
      (t, "none\n\n0")

def dv.last(xs: List<&2, U32>, +f: U32) -> U32:
  match xs:
    case Nil{}:
      f
    case Con{+x, rest}:
      dv.last(rest, S.sr.face(x))

def dv.sub.go(over: Bool, t: Array<U32>, +c: C.Cube, +ps: List<&2, U32>, +b: U32) -> Array<U32> & String:
  match over:
    case True{}:
      (t, "none\n\n0")
    case False{}:
      +k = K.co.of(C.cube.apply(ps, c))
      dv.say(c, S.sr.below(U32.to_nat(U32.sub(b, dv.len.of(ps))), t, dv.cp(k), dv.tw(k), dv.ea(k), dv.eb(k),
        dv.last(ps, 6), List.reverse(&2, U32, ps)))

# the sequences of b moves from the cube that begin with the moves p (one
# of dv.prefixes): one subtree of bound b, independent of the others
def dv.sub(t: Array<U32>, +r: Root, +p: String, +b: U32) -> Array<U32> & String:
  match r:
    case Root{+c, k}:
      +ps = Maybe.default(&2, List<&2, U32>, C.cube.read(p), Nil{})
      dv.sub.go(U32.is_ge(dv.len.of(ps), b), t, c, ps, b)
    case NoRoot{w}:
      (t, "none\n\n0")

# The canonical sequences of n moves (Search.bend's rules: never a face
# twice in a row, a face and the one across in one order), last first in ms
def dv.pre.go(+n: Nat, k: Nat, ok: Bool, +ms: List<&2, U32>, +lf: U32, +m: U32) -> List<&2, String>:
  match n k ok:
    case 0n _ _:
      [C.cube.nums(List.reverse(&2, U32, ms))]
    case 1n+q 0n _:
      Nil{}
    case 1n+q 1n+kq True{}:
      +f = S.sr.face(m)
      +mn = U32.add(m, 1)
      List.append(&2, String, dv.pre.go(q, 18n, S.sr.allowed(0, f), m <> ms, f, 0),
        dv.pre.go(n, kq, S.sr.allowed(mn, lf), ms, lf, mn))
    case 1n+q 1n+kq False{}:
      +mn = U32.add(m, 1)
      dv.pre.go(n, kq, S.sr.allowed(mn, lf), ms, lf, mn)

# xs joined by spaces after acc (a loop: String.join recurses once a word,
# 3,240 deep here, past what a phone's Web Worker allows)
def dv.join(xs: List<&2, String>, +acc: String) -> String:
  match xs:
    case Nil{}:
      acc
    case Con{+x, rest}:
      dv.join(rest, Bool.pick(String, String.is_empty(acc), x, acc ++ " " ++ x))

# the prefixes a bound's search is split by, joined by spaces
def dv.prefixes(+n: Nat) -> String:
  dv.join(dv.pre.go(n, 18n, True{}, Nil{}, 6, 0), "")

# A short way at once (Lite.bend's two-phase)
# -------------------------------------------

# the cube turned so that axis a (0: U-D, 1, 2: by URF3 once, twice) is U-D
def dv.axis(+c: C.Cube, +a: U32) -> C.Cube:
  +c1 = Y.sy.conj(c, Y.sy.URF3())
  Bool.pick(C.Cube, U32.is_eq(a, 0), c, Bool.pick(C.Cube, U32.is_eq(a, 1), c1, Y.sy.conj(c1, Y.sy.URF3())))

# a solution of the cube turned onto axis a, turned back
def dv.back(+xs: List<&2, U32>, +a: U32) -> List<&2, U32>:
  Bool.pick(List<&2, U32>, U32.is_eq(a, 0), xs,
    Bool.pick(List<&2, U32>, U32.is_eq(a, 1), Y.sy.urf.ms(Y.sy.urf.ms(xs)), Y.sy.urf.ms(xs)))

def dv.two.go(r: Array<U32> & L.Best, +c: C.Cube, +a: U32) -> Array<U32> & String:
  (t, b) = r
  match b:
    case L.Best{Some{+xs}, +len, tries, nodes}:
      +sol = dv.back(xs, a)
      +ok = C.cube.is_solved(C.cube.apply(sol, c))
      (t, Bool.pick(String, ok, "ok", "WRONG") ++ "\n" ++ C.cube.nums(sol) ++ "\n" ++ U32.show(len))
    case L.Best{None{}, len, tries, nodes}:
      (t, "none\n\n0")

# a short way for the cube, by two-phase on axis a (three calls, one per
# axis, may run at once): "ok", the moves, their count
def dv.two(t: Array<U32>, +r: Root, +a: U32) -> Array<U32> & String:
  match r:
    case Root{+c, k}:
      dv.two.go(L.lt.solve.cube(t, dv.axis(c, a)), c, a)
    case NoRoot{w}:
      (t, "none\n\n0")
