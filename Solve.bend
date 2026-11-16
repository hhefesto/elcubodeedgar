import Base
import ./Cube.bend as C
import ./Coord.bend as K
import ./Search.bend as S
import ./Par.bend as P

# The solver as a server keeps it: the tables built once, eight copies (one
# per lane), and a solve that hands them back for the next.
#
# A solve: the distance bound of the cube (the three tables' maximum) is the
# first bound; each bound up to 8 is searched on one lane, from 9 on every
# lane (Par.bend), until a bound has a solution. The first solution is a
# shortest one (Search.bend). Bounds stop at 20: every cube is at most 20
# moves from solved (Rokicki, Kociemba, Davidson, Dethridge, 2010).
#
# Every def is prefixed `sv.`.

# A solve's answer: the moves, if found; the nodes made; the last bound
type Ans is Data:
  Ans{+moves: Maybe<&2, List<&2, U32>>, +nodes: U32, +bound: U32}

# The tables
# ----------

def sv.levels(n: Nat, r: Array<U32> & U32, +k: K.Tab, +d: U32) -> Array<U32>:
  match n:
    case 0n:
      (t, v) = r
      t
    case 1n+q:
      (t, +c) = r
      sv.levels(q, K.co.level(t, k, d), k, U32.add(d, 1))

def sv.seed(t: Array<U32>, +off: U32, +i: U32) -> Array<U32>:
  Array.set(U32, t, U32.add(off, U32.shrn(i, 3n)), K.co.lower.w(4294967295, i, 0))

# the move tables, then the three distance tables, breadth first from solved
def sv.tables() -> Array<U32>:
  +s = K.co.of(C.cube.solved())
  t0 = K.co.moves.fill([4294967295 : U32^26n])
  t1 = sv.seed(sv.seed(sv.seed(t0, K.co.T.pc(), 0), K.co.T.pa(), P.pl.ea(s)), K.co.T.pb(), P.pl.eb(s))
  t2 = sv.levels(12n, (t1, 0), K.KC{}, 0)
  t3 = sv.levels(12n, (t2, 0), K.KE{K.co.T.pa()}, 0)
  sv.levels(12n, (t3, 0), K.KE{K.co.T.pb()}, 0)

# eight copies of them
def sv.lanes() -> P.Ts:
  P.pl.lanes(sv.tables())

# On the first lane
# ----------------

def sv.h.leaf(x: Array<U32> & U32) -> P.Ts & U32:
  (t, +h) = x
  (P.TLeaf{t}, h)

def sv.h.node(x: P.Ts & U32, r: P.Ts) -> P.Ts & U32:
  (l, +h) = x
  (P.TNode{l, r}, h)

# the cube's distance bound, read on the first lane
def sv.h(ts: P.Ts, +cp: U32, +tw: U32, +ea: U32, +eb: U32) -> P.Ts & U32:
  match ts:
    case P.TLeaf{t}:
      sv.h.leaf(S.sr.h(t, cp, tw, ea, eb))
    case P.TNode{l, r}:
      sv.h.node(sv.h(l, cp, tw, ea, eb), r)

def sv.ser.node(x: P.Ts & S.Res, r: P.Ts) -> P.Ts & S.Res:
  (l, res) = x
  (P.TNode{l, r}, res)

# a search of depth d from the cube, on the first lane
def sv.ser(ts: P.Ts, +d: Nat, +cp: U32, +tw: U32, +ea: U32, +eb: U32) -> P.Ts & S.Res:
  match ts:
    case P.TLeaf{t}:
      P.pl.leaf(S.sr.below(d, t, cp, tw, ea, eb, 6, Nil{}))
    case P.TNode{l, r}:
      sv.ser.node(sv.ser(l, d, cp, tw, ea, eb), r)

# The search
# ----------

# bound b: on one lane below 9, on every lane from 9
def sv.round(ts: P.Ts, +b: U32, +c: K.Coords, +ps: List<&2, P.Pre>, par: Bool) -> P.Ts & S.Res:
  match par:
    case True{}:
      P.pl.go(ts, P.pl.deal(ps), b)
    case False{}:
      sv.ser(ts, U32.to_nat(b), P.pl.cp(c), P.pl.tw(c), P.pl.ea(c), P.pl.eb(c))

# after bound b's round: its solution, or the next bound (n bounds left)
def sv.fin(ts: P.Ts, res: S.Res, +b: U32, +tot: U32) -> P.Ts & Ans:
  match res:
    case S.Res{f, k}:
      (ts, Ans{f, U32.add(tot, k), b})

def sv.next(n: Nat, r: P.Ts & S.Res, +b: U32, +tot: U32, +c: K.Coords, +ps: List<&2, P.Pre>) -> P.Ts & Ans:
  match n:
    case 0n:
      (ts, res) = r
      sv.fin(ts, res, b, tot)
    case 1n+q:
      (ts, res) = r
      match res:
        case S.Res{f, k}:
          match f:
            case Some{ms}:
              (ts, Ans{Some{ms}, U32.add(tot, k), b})
            case None{}:
              +b1 = U32.add(b, 1)
              sv.next(q, sv.round(ts, b1, c, ps, U32.is_ge(b1, 9)), b1, U32.add(tot, k), c, ps)

def sv.start.go(zero: Bool, ts: P.Ts, +h: U32, +c: K.Coords, +cube: C.Cube) -> P.Ts & Ans:
  match zero:
    case True{}:
      (ts, Ans{Some{Nil{}}, 0, 0})
    case False{}:
      +ps = P.pl.prefixes(3n, cube)
      sv.next(U32.to_nat(U32.sub(20, h)), sv.round(ts, h, c, ps, U32.is_ge(h, 9)), h, 0, c, ps)

def sv.start(r: P.Ts & U32, +c: K.Coords, +cube: C.Cube) -> P.Ts & Ans:
  (ts, +h) = r
  sv.start.go(U32.is_zero(h), ts, h, c, cube)

# A shortest solution of the cube the moves ms make from solved
def sv.solve(ts: P.Ts, +ms: List<&2, U32>) -> P.Ts & Ans:
  +cube = C.cube.apply(ms, C.cube.solved())
  +c = K.co.of(cube)
  sv.start(sv.h(ts, P.pl.cp(c), P.pl.tw(c), P.pl.ea(c), P.pl.eb(c)), c, cube)

