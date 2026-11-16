import Base
import ./Cube.bend as C
import ./Coord.bend as K
import ./Search.bend as S

# The search on every core: a bound's tree split at its first three moves.
#
# The nodes three moves down (the prefixes, each a canonical sequence of
# three) cover the bound's tree: below them is all of it but its first three
# levels. A round deals some prefixes to eight lanes, each with a copy of the
# tables, and the lanes run at once (Bend's parallel calls, one per core);
# a lane goes through its prefixes in turn, stopping at a solution. The first
# solution of the bound, in the lanes' order, is the answer: any of the
# bound's is a shortest one.
#
# Every def is prefixed `pl.`.

# A prefix: its moves in order, and where they lead
type Pre is Data:
  Pre{+ms: List<&2, U32>, +c: K.Coords, +lf: U32}

def pl.cp(+c: K.Coords) -> U32:
  match c:
    case K.Coords{cp, tw, a, fa, b, fb}:
      cp

def pl.tw(+c: K.Coords) -> U32:
  match c:
    case K.Coords{cp, tw, a, fa, b, fb}:
      tw

def pl.ea(+c: K.Coords) -> U32:
  match c:
    case K.Coords{cp, tw, a, fa, b, fb}:
      U32.add(U32.shln(a, 6n), fa)

def pl.eb(+c: K.Coords) -> U32:
  match c:
    case K.Coords{cp, tw, a, fa, b, fb}:
      U32.add(U32.shln(b, 6n), fb)

# The canonical sequences of n moves from c (ms the moves so far, last
# first; lf the last face; m the move tried, k how many are left to try, ok
# whether m may follow lf)
def pl.gen(+n: Nat, k: Nat, ok: Bool, +c: C.Cube, +ms: List<&2, U32>, +lf: U32, +m: U32) -> List<&2, Pre>:
  match n k ok:
    case 0n _ _:
      [Pre{List.reverse(&2, U32, ms), K.co.of(c), lf}]
    case 1n+q 0n _:
      Nil{}
    case 1n+q 1n+kq True{}:
      +f = S.sr.face(m)
      +mn = U32.add(m, 1)
      List.append(&2, Pre, pl.gen(q, 18n, S.sr.allowed(0, f), C.cube.mul(c, C.cube.move(m)), m <> ms, f, 0),
        pl.gen(n, kq, S.sr.allowed(mn, lf), c, ms, lf, mn))
    case 1n+q 1n+kq False{}:
      +mn = U32.add(m, 1)
      pl.gen(n, kq, S.sr.allowed(mn, lf), c, ms, lf, mn)

def pl.prefixes(+n: Nat, +c: C.Cube) -> List<&2, Pre>:
  pl.gen(n, 18n, True{}, c, Nil{}, 6, 0)

# The tables, one copy per lane; the prefixes, one list per lane
type Ts is Type:
  TLeaf{t: Array<U32>}
  TNode{l: Ts, r: Ts}

type W is Data:
  WLeaf{+ps: List<&2, Pre>}
  WNode{+l: W, +r: W}

# 2^(d + 1) lanes from the two copies of r
def pl.lanes.go(+d: Nat, r: Array<U32> & Array<U32>) -> Ts:
  match d:
    case 0n:
      (a, b) = r
      TNode{TLeaf{a}, TLeaf{b}}
    case 1n+q:
      (a, b) = r
      TNode{pl.lanes.go(q, Array.clone(U32, a)), pl.lanes.go(q, Array.clone(U32, b))}

# eight copies of the tables
def pl.lanes(t: Array<U32>) -> Ts:
  pl.lanes.go(2n, Array.clone(U32, t))

# a list dealt in two, alternately
def pl.alt(xs: List<&2, Pre>, a: List<&2, Pre>, b: List<&2, Pre>) -> List<&2, Pre> & List<&2, Pre>:
  match xs:
    case Nil{}:
      (List.reverse(&2, Pre, a), List.reverse(&2, Pre, b))
    case Con{+x, t}:
      pl.alt(t, b, x <> a)

def pl.deal.go(+d: Nat, r: List<&2, Pre> & List<&2, Pre>) -> W:
  match d:
    case 0n:
      (a, b) = r
      WNode{WLeaf{a}, WLeaf{b}}
    case 1n+q:
      (a, b) = r
      WNode{pl.deal.go(q, pl.alt(a, Nil{}, Nil{})), pl.deal.go(q, pl.alt(b, Nil{}, Nil{}))}

# the prefixes dealt to eight lanes, as the copies are laid out
def pl.deal(xs: List<&2, Pre>) -> W:
  pl.deal.go(2n, pl.alt(xs, Nil{}, Nil{}))

# A lane's prefixes, one after the other, at bound b (each with b - 3 moves
# left below it), until one finds a solution
def pl.add2(t: Array<U32>, res: S.Res, +acc: S.Res) -> Array<U32> & S.Res:
  match res acc:
    case S.Res{f, n} S.Res{g, k}:
      (t, S.Res{f, U32.add(n, k)})

def pl.add(r: Array<U32> & S.Res, +acc: S.Res) -> Array<U32> & S.Res:
  (t, res) = r
  pl.add2(t, res, acc)

def pl.one(stop: Bool, +p: Pre, t: Array<U32>, +b: U32, +acc: S.Res) -> Array<U32> & S.Res:
  match stop p:
    case True{} _:
      (t, acc)
    case False{} Pre{ms, c, lf}:
      pl.add(S.sr.below(U32.to_nat(U32.sub(b, 3)), t, pl.cp(c), pl.tw(c), pl.ea(c), pl.eb(c), lf, List.reverse(&2, U32, ms)), acc)

def pl.lane(ps: List<&2, Pre>, r: Array<U32> & S.Res, +b: U32) -> Array<U32> & S.Res:
  match ps:
    case Nil{}:
      r
    case Con{+p, rest}:
      (t, +acc) = r
      pl.lane(rest, pl.one(S.sr.found(acc), p, t, b, acc), b)

def pl.leaf(r: Array<U32> & S.Res) -> Ts & S.Res:
  (t, res) = r
  (TLeaf{t}, res)

# the left lane's solution if it has one, else the right's; nodes summed
def pl.join2(l: Ts, rx: S.Res, r: Ts, ry: S.Res) -> Ts & S.Res:
  match rx ry:
    case S.Res{Some{ms}, n} S.Res{g, k}:
      (TNode{l, r}, S.Res{Some{ms}, U32.add(n, k)})
    case S.Res{None{}, n} S.Res{g, k}:
      (TNode{l, r}, S.Res{g, U32.add(n, k)})

def pl.join(x: Ts & S.Res, y: Ts & S.Res) -> Ts & S.Res:
  (l, rx) = x
  (r, ry) = y
  pl.join2(l, rx, r, ry)

# every lane at once
def pl.go(ts: Ts, ws: W, +b: U32) -> Ts & S.Res:
  match ts ws:
    case TLeaf{t} WLeaf{ps}:
      pl.leaf(pl.lane(ps, (t, S.Res{None{}, 0}), b))
    case TNode{l, r} WNode{wl, wr}:
      x y = pl.go(l, wl, b) pl.go(r, wr, b)
      pl.join(x, y)
    case TLeaf{t} WNode{wl, wr}:
      (TLeaf{t}, S.Res{None{}, 0})
    case TNode{l, r} WLeaf{ps}:
      (TNode{l, r}, S.Res{None{}, 0})

# the first k of xs, and the rest
def pl.take(k: Nat, xs: List<&2, Pre>, acc: List<&2, Pre>) -> List<&2, Pre> & List<&2, Pre>:
  match k xs:
    case 1n+q Con{+x, t}:
      pl.take(q, t, x <> acc)
    case _ _:
      (List.reverse(&2, Pre, acc), xs)
