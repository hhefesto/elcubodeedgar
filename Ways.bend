import Base
import ./Cube.bend as C

# The ways people solve a cube, step by step, beside the solver's fewest
# moves: what the page's "Solve it your way" shows (App.bend's ways.panel),
# worked out on the visitor's device (web/ways-worker.js). Three ways:
#
#   1 CFOP ("F2L")       the cross on the bottom, the four F2L pairs, OLL, PLL
#   2 CFOP, simplified    the same cross and pairs, then the top in four
#                         looks: 2-look OLL, 2-look PLL
#   3 the beginner's      layer by layer: the cross an edge at a time, the
#                         bottom corners, the middle edges, the top's cross,
#                         edges, corners to their places, corners turned
#
# A way is a list of steps, each a goal (some pieces home, or only turned
# right; what earlier steps did kept) and how it gets there:
#
#   a search  the fewest moves to the goal: IDA* (Korf, 1985) over the
#             pieces it follows, bounded by small exact tables (a
#             breadth-first search from solved over one to three pieces):
#             the cross (CFOP's at once, the beginner's an edge at a time),
#             each F2L pair (the one of those left with the fewest moves)
#   macros    the step's algorithms (J Perm's OLL and PLL, the beginner's
#             R U R' U' ...), each from any of the four sides, and the top
#             turned: every sequence of up to a few of them, the one with
#             the fewest moves that reaches the goal (wy.md)
#
# Every way's moves are checked by Cube.bend before they are shown: the
# scramble, then them, leaves the cube solved (and the page checks again).
# ALGS.bend has the algorithms' laws; probe/WaysT.bend runs 200 scrambles.
#
# Pieces, as Cube.bend numbers them: a corner's state is its place * 3 + its
# twist (0..23), an edge's 24 + its place * 2 + its flip (24..47).
#
# The array (2^20 words, made once on the device, wy.tables):
#   0        the move table: at v * 18 + m, piece state v after move m
#   1024     the breadth-first search's queue (a table's states, 13824 at most)
#   17408    one piece's distances (4 tables: the cross's edges), 32 words each
#   18432    two pieces' (6: two of the cross's edges), 1024 each
#   32768    three's (4: three of the cross's edges), 32768 each
#   163840   an F2L pair with one cross edge (16: four slots, four edges)
# A table's entry is at its base + the pieces' states, 5 bits each (an
# edge's less 24), first piece highest; 255 is a state no move reaches.
#
# Every def is prefixed `wy.`.

# Lists
# -----

# the place of x in xs, from i (i + the length if x is not there)
def wy.find(xs: List<&2, U32>, +x: U32, +i: U32) -> U32:
  match xs:
    case Nil{}:
      i
    case Con{+y, t}:
      Bool.pick(U32, U32.is_eq(y, x), i, wy.find(t, x, U32.add(i, 1)))

def wy.len(xs: List<&2, U32>) -> U32:
  U32.from_nat(List.length(&2, U32, xs))

# a move's face: m / 3, for m < 18 (as Search.bend's sr.face)
def wy.face(+m: U32) -> U32:
  U32.shrn(U32.mul(m, 11), 5n)

# whether move m may follow a turn of face lf (6: none): not the same face,
# and a face and the one across in one order only (U before D)
def wy.allowed(+m: U32, +lf: U32) -> Bool:
  +f = wy.face(m)
  Bool.and(U32.is_ne(f, lf), Bool.or(U32.is_ge(f, 3), U32.is_ne(U32.add(f, 3), lf)))

# Moves merged: each run of one face's turns as one (as App.bend's pos.simp)
def wy.merge(same: Bool, +m: U32, +top: U32, +rest: List<&2, U32>) -> List<&2, U32>:
  match same:
    case False{}:
      m <> (top <> rest)
    case True{}:
      +q = U32.and(U32.add(U32.add(U32.mod(top, 3), U32.mod(m, 3)), 2), 3)
      Bool.pick(List<&2, U32>, U32.is_zero(q), rest, U32.add(U32.sub(top, U32.mod(top, 3)), U32.sub(q, 1)) <> rest)

def wy.push(+m: U32, st: List<&2, U32>) -> List<&2, U32>:
  match st:
    case Nil{}:
      [m]
    case Con{+top, +rest}:
      wy.merge(U32.is_eq(wy.face(top), wy.face(m)), m, top, rest)

def wy.simp.go(ms: List<&2, U32>, st: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      List.reverse(&2, U32, st)
    case Con{+m, t}:
      wy.simp.go(t, wy.push(m, st))

def wy.simp(ms: List<&2, U32>) -> List<&2, U32>:
  wy.simp.go(ms, Nil{})

# Pieces
# ------

# where move m takes a corner at place p twisted o: to the place j that
# m.cp[j] = p names (Kociemba's (s * m).cp[j] = s.cp[m.cp[j]]), twisted
# m.co[j] more
def wy.mt.c(+mc: C.Cube, +p: U32, +o: U32) -> U32:
  match mc:
    case C.Cube{+cp, +co, ep, eo}:
      +j = wy.find(cp, p, 0)
      U32.add(U32.mul(j, 3), U32.mod(U32.add(o, C.cube.at(co, j)), 3))

def wy.mt.e(+mc: C.Cube, +p: U32, +o: U32) -> U32:
  match mc:
    case C.Cube{cp, co, +ep, +eo}:
      +j = wy.find(ep, p, 0)
      U32.add(24, U32.add(U32.mul(j, 2), U32.and(U32.add(o, C.cube.at(eo, j)), 1)))

# piece state v after move m
def wy.mt.val(+v: U32, +m: U32) -> U32:
  +mc = C.cube.move(m)
  Bool.pick(U32, U32.is_lt(v, 24), wy.mt.c(mc, U32.div(v, 3), U32.mod(v, 3)),
    wy.mt.e(mc, U32.shrn(U32.sub(v, 24), 1n), U32.and(v, 1)))

def wy.fill.mt(n: Nat, t: Array<U32>, +k: U32) -> Array<U32>:
  match n:
    case 0n:
      t
    case 1n+p:
      wy.fill.mt(p, Array.set(U32, t, k, wy.mt.val(U32.div(k, 18), U32.mod(k, 18))), U32.add(k, 1))

# a piece's state in a table's index: an edge's less 24
def wy.loc(+v: U32) -> U32:
  Bool.pick(U32, U32.is_lt(v, 24), v, U32.sub(v, 24))

def wy.ix.go(vs: List<&2, U32>, +acc: U32) -> U32:
  match vs:
    case Nil{}:
      acc
    case Con{+v, t}:
      wy.ix.go(t, U32.add(U32.shln(acc, 5n), wy.loc(v)))

# the pieces' states vs, as a table's index
def wy.ix(vs: List<&2, U32>) -> U32:
  wy.ix.go(vs, 0)

def wy.unix.go(rtg: List<&2, U32>, +i: U32, +acc: List<&2, U32>) -> List<&2, U32>:
  match rtg:
    case Nil{}:
      acc
    case Con{+g, t}:
      wy.unix.go(t, U32.shrn(i, 5n), U32.add(U32.and(i, 31), Bool.pick(U32, U32.is_lt(g, 24), 0, 24)) <> acc)

# index i as the pieces' states (tg: what each piece is when home, for its kind)
def wy.unix(+tg: List<&2, U32>, +i: U32) -> List<&2, U32>:
  wy.unix.go(List.reverse(&2, U32, tg), i, Nil{})

# where piece g (its home state) is in cube c, as a state
def wy.where(+c: C.Cube, +g: U32) -> U32:
  match c:
    case C.Cube{+cp, +co, +ep, +eo}:
      +cj = wy.find(cp, U32.div(g, 3), 0)
      +ej = wy.find(ep, U32.shrn(U32.sub(g, 24), 1n), 0)
      Bool.pick(U32, U32.is_lt(g, 24), U32.add(U32.mul(cj, 3), C.cube.at(co, cj)),
        U32.add(24, U32.add(U32.mul(ej, 2), C.cube.at(eo, ej))))

def wy.wheres(+c: C.Cube, gs: List<&2, U32>) -> List<&2, U32>:
  match gs:
    case Nil{}:
      Nil{}
    case Con{+g, t}:
      wy.where(c, g) <> wy.wheres(c, t)

# Moving pieces through the table
# -------------------------------

# the states vs after move m: each read handed to the next call
def wy.mvs.go(vs: List<&2, U32>, r: Array<U32> & U32, +m: U32, +acc: List<&2, U32>) -> Array<U32> & List<&2, U32>:
  match vs:
    case Nil{}:
      (t, +v) = r
      (t, List.reverse(&2, U32, v <> acc))
    case Con{+x, rest}:
      (t, +v) = r
      wy.mvs.go(rest, t[U32.add(U32.mul(x, 18), m)], m, v <> acc)

def wy.mvs(vs: List<&2, U32>, t: Array<U32>, +m: U32) -> Array<U32> & List<&2, U32>:
  match vs:
    case Nil{}:
      (t, Nil{})
    case Con{+x, rest}:
      wy.mvs.go(rest, t[U32.add(U32.mul(x, 18), m)], m, Nil{})

# The tables: breadth-first from solved
# -------------------------------------

def wy.QB() -> U32:
  1024

# A breadth-first search's state: the array, the queue's head and tail
type BS is Type:
  BS{t: Array<U32>, +head: U32, +tail: U32}

# a child at index c, if unseen (its entry 255): d there, and onto the queue
def wy.put(fresh: Bool, t: Array<U32>, +base: U32, +c: U32, +d: U32, +tail: U32) -> Array<U32> & U32:
  match fresh:
    case True{}:
      (Array.set(U32, Array.set(U32, t, U32.add(base, c), d), U32.add(wy.QB(), tail), c), U32.add(tail, 1))
    case False{}:
      (t, tail)

def wy.bfs.c3(r: Array<U32> & U32, +base: U32, +c: U32, +d: U32, +tail: U32) -> Array<U32> & U32:
  (t, +e) = r
  wy.put(U32.is_eq(e, 255), t, base, c, d, tail)

def wy.bfs.c2(r: Array<U32> & List<&2, U32>, +base: U32, +d: U32, +tail: U32) -> Array<U32> & U32:
  (t, cvs) = r
  +c = wy.ix(cvs)
  wy.bfs.c3(t[U32.add(base, c)], base, c, d, tail)

# every move from a node (its states vs; d its children's distance): r is the
# array and the queue's tail
def wy.bfs.mv(ms: List<&2, U32>, r: Array<U32> & U32, +vs: List<&2, U32>, +base: U32, +d: U32) -> Array<U32> & U32:
  match ms:
    case Nil{}:
      (t, +tail) = r
      (t, tail)
    case Con{+m, rest}:
      (t, +tail) = r
      wy.bfs.mv(rest, wy.bfs.c2(wy.mvs(vs, t, m), base, d, tail), vs, base, d)

def wy.bfs.n3(r: Array<U32> & U32, +head: U32) -> BS:
  (t, +tail) = r
  BS{t, U32.add(head, 1), tail}

# the node's entry read: its distance
def wy.bfs.n2(r: Array<U32> & U32, +vs: List<&2, U32>, +base: U32, +head: U32, +tail: U32, +ms: List<&2, U32>) -> BS:
  (t, +d) = r
  wy.bfs.n3(wy.bfs.mv(ms, (t, tail), vs, base, U32.add(d, 1)), head)

# the queue's entry read: the node's index
def wy.bfs.n1(r: Array<U32> & U32, +tg: List<&2, U32>, +base: U32, +head: U32, +tail: U32, +ms: List<&2, U32>) -> BS:
  (t, +c) = r
  wy.bfs.n2(t[U32.add(base, c)], wy.unix(tg, c), base, head, tail, ms)

def wy.bfs.step(more: Bool, t: Array<U32>, +tg: List<&2, U32>, +base: U32, +head: U32, +tail: U32, +ms: List<&2, U32>) -> BS:
  match more:
    case True{}:
      wy.bfs.n1(t[U32.add(wy.QB(), head)], tg, base, head, tail, ms)
    case False{}:
      BS{t, head, tail}

# n steps, each the queue's next node (none once it is empty)
def wy.bfs(n: Nat, s: BS, +tg: List<&2, U32>, +base: U32, +ms: List<&2, U32>) -> Array<U32>:
  match n s:
    case 0n BS{t, head, tail}:
      t
    case 1n+p BS{t, +head, +tail}:
      wy.bfs(p, wy.bfs.step(U32.is_lt(head, tail), t, tg, base, head, tail, ms), tg, base, ms)

# every move
def wy.all18() -> List<&2, U32>:
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]

# the table of the pieces tg (their home states) at base: 0 at solved, then
# each state's distance; 24^k states at most
def wy.table(t: Array<U32>, +tg: List<&2, U32>, +base: U32) -> Array<U32>:
  +c = wy.ix(tg)
  wy.bfs(U32.to_nat(U32.pow(24, List.length(&2, U32, tg))),
    BS{Array.set(U32, Array.set(U32, t, U32.add(base, c), 0), wy.QB(), c), 0, 1}, tg, base, wy.all18())

# The pieces a search follows, and the tables
# --------------------------------------------

# Their home states, in the order a search keeps them: the cross's edges DR
# DF DL DB (0..3), the bottom corners DFR DLF DBL DRB (4..7), the middle
# edges FR FL BL BR (8..11). A slot q (front right, front left, back left,
# back right: 0..3) is corner 4 + q with edge 8 + q.
def wy.homes() -> List<&2, U32>:
  [32, 34, 36, 38, 12, 15, 18, 21, 40, 42, 44, 46]

# A table: where it is, and which of those pieces it is over (their places
# in that order, first highest in its index)
type Tb is Data:
  Tb{+base: U32, +ps: List<&2, U32>}

# one cross edge i
def wy.e1(+i: U32) -> Tb:
  Tb{U32.add(17408, U32.mul(i, 32)), [i]}

# two cross edges i < j: (0,1) (0,2) (0,3) (1,2) (1,3) (2,3)
def wy.e2(+i: U32, +j: U32) -> Tb:
  +k = U32.add(U32.sub(U32.add(U32.mul(i, 3), j), 1), Bool.pick(U32, U32.is_ge(i, 1), U32.sub(U32.sub(i, 1), U32.shrn(i, 1n)), 0))
  Tb{U32.add(18432, U32.mul(k, 1024)), [i, j]}

# three cross edges: all but s
def wy.e3(+s: U32) -> Tb:
  Tb{U32.add(32768, U32.mul(s, 32768)),
     Bool.pick(List<&2, U32>, U32.is_eq(s, 0), [1, 2, 3], Bool.pick(List<&2, U32>, U32.is_eq(s, 1), [0, 2, 3], Bool.pick(List<&2, U32>, U32.is_eq(s, 2), [0, 1, 3], [0, 1, 2])))}

# slot q's pair, with cross edge x
def wy.pr(+q: U32, +x: U32) -> Tb:
  Tb{U32.add(163840, U32.mul(U32.add(U32.mul(q, 4), x), 32768)), [U32.add(4, q), U32.add(8, q), x]}

def wy.e3s() -> List<&2, Tb>:
  [wy.e3(0), wy.e3(1), wy.e3(2), wy.e3(3)]

def wy.prs(+q: U32) -> List<&2, Tb>:
  [wy.pr(q, 0), wy.pr(q, 1), wy.pr(q, 2), wy.pr(q, 3)]

def wy.e2s() -> List<&2, Tb>:
  [wy.e2(0, 1), wy.e2(0, 2), wy.e2(0, 3), wy.e2(1, 2), wy.e2(1, 3), wy.e2(2, 3)]

def wy.alltbs() -> List<&2, Tb>:
  List.concat(&2, Tb, [[wy.e1(0), wy.e1(1), wy.e1(2), wy.e1(3)], wy.e2s(), wy.e3s(), wy.prs(0), wy.prs(1), wy.prs(2), wy.prs(3)])

def wy.tg(ps: List<&2, U32>) -> List<&2, U32>:
  match ps:
    case Nil{}:
      Nil{}
    case Con{+p, t}:
      C.cube.at(wy.homes(), p) <> wy.tg(t)

def wy.build1(t: Array<U32>, +tb: Tb) -> Array<U32>:
  match tb:
    case Tb{+base, +ps}:
      wy.table(t, wy.tg(ps), base)

def wy.build(tbs: List<&2, Tb>, t: Array<U32>) -> Array<U32>:
  match tbs:
    case Nil{}:
      t
    case Con{+tb, rest}:
      wy.build(rest, wy.build1(t, tb))

# Every table, made once (2^20 words; about a second on a phone)
def wy.tables() -> Array<U32>:
  wy.build(wy.alltbs(), wy.fill.mt(864n, [255 : U32^20n], 0))

# A search's distance bound
# -------------------------

# the index of the pieces ps (their places in vs, the states)
def wy.ixp(ps: List<&2, U32>, +vs: List<&2, U32>, +acc: U32) -> U32:
  match ps:
    case Nil{}:
      acc
    case Con{+p, t}:
      wy.ixp(t, vs, U32.add(U32.shln(acc, 5n), wy.loc(C.cube.at(vs, p))))

def wy.mx(r: Array<U32> & U32, +acc: U32) -> Array<U32> & U32:
  (t, +v) = r
  (t, U32.max(v, acc))

def wy.mn(r: Array<U32> & U32, +acc: U32) -> Array<U32> & U32:
  (t, +v) = r
  (t, U32.min(v, acc))

def wy.tvm(t: Array<U32>, +tb: Tb, +vs: List<&2, U32>, +acc: U32) -> Array<U32> & U32:
  match tb:
    case Tb{+base, +ps}:
      wy.mx(t[U32.add(base, wy.ixp(ps, vs, 0))], acc)

# the tables' largest entry: each is a number of moves no fewer than the
# moves it takes to bring its pieces home
def wy.hmax(tbs: List<&2, Tb>, r: Array<U32> & U32, +vs: List<&2, U32>) -> Array<U32> & U32:
  match tbs:
    case Nil{}:
      r
    case Con{+tb, rest}:
      (t, +acc) = r
      wy.hmax(rest, wy.tvm(t, tb, vs, acc), vs)

# the least of the groups' largest
def wy.hmin(gs: List<&2, List<&2, Tb>>, r: Array<U32> & U32, +vs: List<&2, U32>) -> Array<U32> & U32:
  match gs:
    case Nil{}:
      r
    case Con{+g, rest}:
      (t, +acc) = r
      wy.hmin(rest, wy.mn(wy.hmax(g, (t, 0), vs), acc), vs)

# A step's goal, for a search: every piece of the tables in must home, and
# those of one group of any (each group a way to be done: one more cross
# edge, one more pair). A table's entry is 0 just when its pieces are home,
# so the bound is 0 just at the goal.
type Sp is Data:
  Sp{+must: List<&2, Tb>, +any: List<&2, List<&2, Tb>>}

def wy.h2(r: Array<U32> & U32, +any: List<&2, List<&2, Tb>>, +vs: List<&2, U32>) -> Array<U32> & U32:
  (t, +a) = r
  wy.mx(wy.hmin(any, (t, 255), vs), a)

def wy.h(t: Array<U32>, +sp: Sp, +vs: List<&2, U32>) -> Array<U32> & U32:
  match sp:
    case Sp{+must, +any}:
      wy.h2(wy.hmax(must, (t, 0), vs), any, vs)

# The search: IDA* (Korf, 1985)
# -----------------------------

# What it found: whether it reached the goal, the moves (in order), the least
# a bound must grow by to look further, the nodes made
type Rs is Data:
  Rs{+got: Bool, +ms: List<&2, U32>, +x: U32, +n: U32}

def wy.rs.got(+r: Rs) -> Bool:
  match r:
    case Rs{+g, +ms, +x, +n}:
      g

def wy.rs.ms(+r: Rs) -> List<&2, U32>:
  match r:
    case Rs{+g, +ms, +x, +n}:
      ms

def wy.rs.x(+r: Rs) -> U32:
  match r:
    case Rs{+g, +ms, +x, +n}:
      x

def wy.rs.n(+r: Rs) -> U32:
  match r:
    case Rs{+g, +ms, +x, +n}:
      n

# a child: its states and its bound
type Kd is Data:
  Kd{+vs: List<&2, U32>, +h: U32}

def wy.kd.vs(+k: Kd) -> List<&2, U32>:
  match k:
    case Kd{+vs, +h}:
      vs

def wy.kd.h(+k: Kd) -> U32:
  match k:
    case Kd{+vs, +h}:
      h

def wy.kid3(r: Array<U32> & U32, +v2: List<&2, U32>) -> Array<U32> & Kd:
  (t, +h) = r
  (t, Kd{v2, h})

def wy.kid2(r: Array<U32> & List<&2, U32>, +sp: Sp) -> Array<U32> & Kd:
  (t, +v2) = r
  wy.kid3(wy.h(t, sp, v2), v2)

def wy.kid(t: Array<U32>, +vs: List<&2, U32>, +m: U32, +sp: Sp) -> Array<U32> & Kd:
  wy.kid2(wy.mvs(vs, t, m), sp)

def wy.keep(k: Bool, +m: U32, xs: List<&2, U32>) -> List<&2, U32>:
  match k:
    case True{}:
      m <> xs
    case False{}:
      xs

def wy.after.go(ms: List<&2, U32>, +lf: U32) -> List<&2, U32>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+m, t}:
      wy.keep(wy.allowed(m, lf), m, wy.after.go(t, lf))

# the moves that may follow a turn of face lf (6: none)
def wy.after(+lf: U32) -> List<&2, U32>:
  wy.after.go(wy.all18(), lf)

# What a step of the search does next
type Op is Data:
  OTry{}
  OKid{}
  ODec{}
  OBack{}
  OCont{}

# The array, alone; with a child; or with a child's search
type Cy is Type:
  CT{t: Array<U32>}
  CK{r: Array<U32> & Kd}
  CR{r: Array<U32> & Rs}

def wy.go.out(c: Cy, +acc: U32, +nodes: U32) -> Array<U32> & Rs:
  match c:
    case CT{t}:
      (t, Rs{False{}, [], acc, nodes})
    case CK{r}:
      (t, k) = r
      (t, Rs{False{}, [], acc, nodes})
    case CR{r}:
      r

# The search below a node (its states vs, its last face lf, its moves path,
# last first), d moves left (bud: d as a number); ms the moves still to try
# there. Each step of a node is a call with less fuel; a child's search, a
# call with less d:
#   OTry  the next move's child (CK: its states and bound)
#   ODec  flag: the child is the goal; cut: its bound is past what is left
#   OBack the child's search came back (CR); OCont: flag, it found the goal
def wy.go(
  +d: Nat, fuel: Nat, op: Op, +ms: List<&2, U32>, flag: Bool, cut: Bool, c: Cy,
  +bud: U32, +vs: List<&2, U32>, +v2: List<&2, U32>, +h2: U32, +lf: U32, +path: List<&2, U32>,
  +sp: Sp, +acc: U32, +nodes: U32, +res: Rs
) -> Array<U32> & Rs:
  match d fuel op ms flag cut c:
    case _ 0n _ _ _ _ _:
      wy.go.out(c, acc, nodes)
    case 0n 1n+fq _ _ _ _ _:
      wy.go.out(c, acc, nodes)
    case 1n+dq 1n+fq OTry{} Nil{} _ _ _:
      wy.go.out(c, acc, nodes)
    case 1n+dq 1n+fq OTry{} Con{+m, rest} _ _ CT{t}:
      wy.go(d, fq, OKid{}, ms, False{}, False{}, CK{wy.kid(t, vs, m, sp)},
        bud, vs, v2, h2, lf, path, sp, acc, U32.add(nodes, 1), res)
    case 1n+dq 1n+fq OKid{} _ _ _ CK{r}:
      (t, +k) = r
      +hk = wy.kd.h(k)
      wy.go(d, fq, ODec{}, ms, U32.is_zero(hk), U32.is_ge(hk, bud), CT{t},
        bud, vs, wy.kd.vs(k), hk, lf, path, sp, acc, nodes, res)
    case 1n+dq 1n+fq ODec{} Con{+m, rest} True{} _ CT{t}:
      (t, Rs{True{}, List.reverse(&2, U32, m <> path), 0, nodes})
    case 1n+dq 1n+fq ODec{} Con{+m, rest} False{} True{} CT{t}:
      wy.go(d, fq, OTry{}, rest, False{}, False{}, CT{t},
        bud, vs, v2, h2, lf, path, sp, U32.min(acc, U32.sub(U32.add(h2, 1), bud)), nodes, res)
    case 1n+dq 1n+fq ODec{} Con{+m, rest} False{} False{} CT{t}:
      +f = wy.face(m)
      wy.go(d, fq, OBack{}, ms, False{}, False{},
        CR{wy.go(dq, 255n, OTry{}, wy.after(f), False{}, False{}, CT{t},
          U32.sub(bud, 1), v2, v2, 0, f, m <> path, sp, 255, nodes, res)},
        bud, vs, v2, h2, lf, path, sp, acc, nodes, res)
    case 1n+dq 1n+fq OBack{} _ _ _ CR{r}:
      (t, +cr) = r
      wy.go(d, fq, OCont{}, ms, wy.rs.got(cr), False{}, CT{t},
        bud, vs, v2, h2, lf, path, sp, U32.min(acc, wy.rs.x(cr)), wy.rs.n(cr), cr)
    case 1n+dq 1n+fq OCont{} _ True{} _ CT{t}:
      (t, res)
    case 1n+dq 1n+fq OCont{} Con{+m, rest} False{} _ CT{t}:
      wy.go(d, fq, OTry{}, rest, False{}, False{}, CT{t},
        bud, vs, v2, h2, lf, path, sp, acc, nodes, res)
    case _ 1n+fq _ _ _ _ _:
      wy.go.out(c, acc, nodes)

# a search under bound b from the node vs, unless one found the goal already
def wy.ida.again(got: Bool, t: Array<U32>, +res: Rs, +b: U32, +vs: List<&2, U32>, +sp: Sp) -> Array<U32> & Rs:
  match got:
    case True{}:
      (t, res)
    case False{}:
      wy.go(U32.to_nat(b), 255n, OTry{}, wy.after(6), False{}, False{}, CT{t},
        b, vs, vs, 0, 6, [], sp, 255, wy.rs.n(res), Rs{False{}, [], 255, wy.rs.n(res)})

# bounds growing by the least that looks further, n times at most (or past
# 20 moves: no step needs that many)
def wy.ida(n: Nat, r: Array<U32> & Rs, +b: U32, +vs: List<&2, U32>, +sp: Sp) -> Array<U32> & Rs:
  match n:
    case 0n:
      r
    case 1n+p:
      (t, +res) = r
      +nb = U32.add(b, wy.rs.x(res))
      wy.ida(p, wy.ida.again(Bool.or(wy.rs.got(res), U32.is_gt(nb, 20)), t, res, nb, vs, sp), nb, vs, sp)

def wy.search.first(z: Bool, t: Array<U32>, +h0: U32, +vs: List<&2, U32>, +sp: Sp) -> Array<U32> & Rs:
  match z:
    case True{}:
      (t, Rs{True{}, [], 0, 0})
    case False{}:
      wy.go(U32.to_nat(h0), 255n, OTry{}, wy.after(6), False{}, False{}, CT{t},
        h0, vs, vs, 0, 6, [], sp, 255, 0, Rs{False{}, [], 255, 0})

def wy.search.go(r: Array<U32> & U32, +vs: List<&2, U32>, +sp: Sp) -> Array<U32> & Rs:
  (t, +h0) = r
  wy.ida(24n, wy.search.first(U32.is_zero(h0), t, h0, vs, sp), h0, vs, sp)

# The fewest moves from the pieces' states vs to the goal sp
def wy.search(t: Array<U32>, +vs: List<&2, U32>, +sp: Sp) -> Array<U32> & Rs:
  wy.search.go(wy.h(t, sp, vs), vs, sp)

# Algorithms as people write them
# -------------------------------
#
# J Perm's notation ("r U R' U' r' F R F'") as face turns of a cube whose
# centers stay put, as this one's do: the moves are the faces in place now
# (o: the face at each of U R F D L B), and turning the whole cube turns no
# face, only which face each letter names after it.
#   R U F D L B   that face; ' back, 2 a half turn (3 is ', 2' is 2)
#   r u f d l b   (or Rw ..) a wide turn: the face across, turned the same
#                 way, with the cube (r = L x, u = D y, f = B z, l = R x' ..)
#   M E S         a middle slice: M = R L' x', E = U D' y', S = F' B z
#   x y z         the cube, as R, U, F turn
# Parentheses are only grouping.

# the faces at each place after a quarter turn of the cube about axis a
# (x, y, z: 0, 1, 2), as R, U, F turn
def wy.rot1(+a: U32, +o: List<&2, U32>) -> List<&2, U32>:
  +u = C.cube.at(o, 0)
  +r = C.cube.at(o, 1)
  +f = C.cube.at(o, 2)
  +d = C.cube.at(o, 3)
  +l = C.cube.at(o, 4)
  +b = C.cube.at(o, 5)
  Bool.pick(List<&2, U32>, U32.is_eq(a, 0), [f, r, d, b, l, u],
    Bool.pick(List<&2, U32>, U32.is_eq(a, 1), [u, b, r, d, f, l], [l, u, f, r, d, b]))

def wy.rot(n: Nat, +a: U32, +o: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      o
    case 1n+p:
      wy.rot(p, a, wy.rot1(a, o))

# quarter turns of the cube for a turn k (0 quarter, 1 half, 2 back), the
# same way as the face (pos) or the other
def wy.qs(+pos: Bool, +k: U32) -> Nat:
  U32.to_nat(Bool.pick(U32, pos, U32.add(k, 1), U32.sub(3, U32.min(k, 2))))

def wy.inv.k(+k: U32) -> U32:
  U32.sub(2, U32.min(k, 2))

# What a word of notation does: the faces after it, its face turns, whether
# it read as one
type Tk is Data:
  Tk{+o: List<&2, U32>, +ms: List<&2, U32>, +ok: Bool}

# a face turn of the face at place p, turn k
def wy.mv(+o: List<&2, U32>, +p: U32, +k: U32) -> U32:
  U32.add(U32.mul(C.cube.at(o, p), 3), k)

# the axis a face turns about, and whether the same way as x, y, z
def wy.axis(+f: U32) -> U32:
  C.cube.at([1, 0, 2, 1, 0, 2], f)

# a letter, its turn k: c the letter, w whether a wide turn
def wy.tk.face(+o: List<&2, U32>, +f: U32, +k: U32, +w: Bool) -> Tk:
  Bool.pick(Tk, w,
    Tk{wy.rot(wy.qs(U32.is_lt(f, 3), k), wy.axis(f), o), [wy.mv(o, U32.mod(U32.add(f, 3), 6), k)], U32.is_lt(k, 3)},
    Tk{o, [wy.mv(o, f, k)], U32.is_lt(k, 3)})

# M E S (s 0..2)
def wy.tk.slice(+o: List<&2, U32>, +s: U32, +k: U32) -> Tk:
  +ik = wy.inv.k(k)
  +ok = U32.is_lt(k, 3)
  Bool.pick(Tk, U32.is_eq(s, 0), Tk{wy.rot(wy.qs(False{}, k), 0, o), [wy.mv(o, 1, k), wy.mv(o, 4, ik)], ok},
    Bool.pick(Tk, U32.is_eq(s, 1), Tk{wy.rot(wy.qs(False{}, k), 1, o), [wy.mv(o, 0, k), wy.mv(o, 3, ik)], ok},
      Tk{wy.rot(wy.qs(True{}, k), 2, o), [wy.mv(o, 2, ik), wy.mv(o, 5, k)], ok}))

# the letter's kind: M E S 0..2, x y z 3..5, else 6
def wy.tk.kind(+c: Char) -> U32:
  +d = Char.to_lower(c)
  Bool.pick(U32, Char.is_eq(c, 'M'), 0, Bool.pick(U32, Char.is_eq(c, 'E'), 1, Bool.pick(U32, Char.is_eq(c, 'S'), 2,
    Bool.pick(U32, Char.is_eq(d, 'x'), 3, Bool.pick(U32, Char.is_eq(d, 'y'), 4, Bool.pick(U32, Char.is_eq(d, 'z'), 5, 6))))))

# what follows the letter: as Cube.bend reads it, and 3 as '
def wy.suf(+s: String) -> U32:
  Bool.pick(U32, String.eq(s, "3"), 2, C.cube.suf.of(s))

def wy.tk2(+c: Char, +rest: String, +o: List<&2, U32>) -> Tk:
  +f = C.cube.face.of(c)
  +up = Char.is_upper(c)
  +rw = Bool.and(up, String.starts_with(rest, "w"))
  +k = wy.suf(Bool.pick(String, rw, String.drop(rest, 1n), rest))
  +kind = wy.tk.kind(c)
  Bool.pick(Tk, Bool.and(U32.is_lt(f, 6), Bool.not(Bool.and(up, U32.is_lt(kind, 3)))), wy.tk.face(o, f, k, Bool.or(rw, Bool.not(up))),
    Bool.pick(Tk, U32.is_lt(kind, 3), wy.tk.slice(o, kind, k),
      Bool.pick(Tk, U32.is_lt(kind, 6), Tk{wy.rot(wy.qs(True{}, k), U32.sub(kind, 3), o), [], U32.is_lt(k, 3)},
        Tk{o, [], False{}})))

def wy.tk(+t: String, +o: List<&2, U32>) -> Tk:
  match t:
    case SNil{}:
      Tk{o, [], True{}}
    case SCon{+c, +rest}:
      wy.tk2(c, rest, o)

def wy.tk.o(+t: Tk) -> List<&2, U32>:
  match t:
    case Tk{+o, +ms, +ok}:
      o

def wy.tk.ms(+t: Tk) -> List<&2, U32>:
  match t:
    case Tk{+o, +ms, +ok}:
      ms

def wy.tk.ok(+t: Tk) -> Bool:
  match t:
    case Tk{+o, +ms, +ok}:
      ok

# Words read: the face turns, and whether every word read
type Nt is Data:
  Nt{+ms: List<&2, U32>, +ok: Bool}

def wy.nt.go(ts: List<&2, String>, +o: List<&2, U32>, +acc: List<&2, U32>, +ok: Bool) -> Nt:
  match ts:
    case Nil{}:
      Nt{acc, ok}
    case Con{+w, rest}:
      +tk = wy.tk(w, o)
      wy.nt.go(rest, wy.tk.o(tk), List.append(&2, U32, acc, wy.tk.ms(tk)), Bool.and(ok, wy.tk.ok(tk)))

def wy.blank(+c: Char) -> Char:
  Bool.pick(Char, Bool.or(Char.is_eq(c, '('), Char.is_eq(c, ')')), ' ', c)

def wy.blanks(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{+c, t}:
      SCon{wy.blank(c), wy.blanks(t)}

# an algorithm's face turns
def wy.nt(+s: String) -> Nt:
  wy.nt.go(String.split(wy.blanks(s), ' '), [0, 1, 2, 3, 4, 5], [], True{})

def wy.nt.of(+n: Nt) -> List<&2, U32>:
  match n:
    case Nt{+ms, +ok}:
      ms

def wy.nt.ok(+n: Nt) -> Bool:
  match n:
    case Nt{+ms, +ok}:
      ok

def wy.nt.ms(+s: String) -> List<&2, U32>:
  wy.nt.of(wy.nt(s))

# The algorithms
# --------------
#
# Each case's first algorithm in J Perm's lists (jperm.net/algs: OLL, PLL,
# 2-look OLL and PLL; the Z perm with the U' it leaves to the end, so it
# keeps the corners home), and the beginner's method's (the layer by layer
# one Rubik's own guide teaches), with the top layer on U: a step tries each
# as it is, and from the three other sides (the cube turned, which costs no
# move), so the top layer needs no turn first.

type Al is Data:
  Al{+name: String, +nt: String}

def wy.oll() -> List<&2, Al>:
  [Al{"case 1", "R U2 R2 F R F' U2 R' F R F'"}, Al{"case 2", "r U r' U2 r U2 R' U2 R U' r'"},
   Al{"case 3", "r' R2 U R' U r U2 r' U M'"}, Al{"case 4", "M U' r U2 r' U' R U' R' M'"},
   Al{"case 5", "l' U2 L U L' U l"}, Al{"case 6", "r U2 R' U' R U' r'"},
   Al{"case 7", "r U R' U R U2 r'"}, Al{"case 8", "l' U' L U' L' U2 l"},
   Al{"case 9", "R U R' U' R' F R2 U R' U' F'"}, Al{"case 10", "R U R' U R' F R F' R U2 R'"},
   Al{"case 11", "r U R' U R' F R F' R U2 r'"}, Al{"case 12", "M' R' U' R U' R' U2 R U' R r'"},
   Al{"case 13", "F U R U' R2 F' R U R U' R'"}, Al{"case 14", "R' F R U R' F' R F U' F'"},
   Al{"case 15", "l' U' l L' U' L U l' U l"}, Al{"case 16", "r U r' R U R' U' r U' r'"},
   Al{"case 17", "F R' F' R2 r' U R U' R' U' M'"}, Al{"case 18", "r U R' U R U2 r2 U' R U' R' U2 r"},
   Al{"case 19", "r' R U R U R' U' M' R' F R F'"}, Al{"case 20", "r U R' U' M2 U R U' R' U' M'"},
   Al{"case 21, H", "R U2 R' U' R U R' U' R U' R'"}, Al{"case 22, Pi", "R U2 R2 U' R2 U' R2 U2 R"},
   Al{"case 23, Headlights", "R2 D' R U2 R' D R U2 R"}, Al{"case 24, T", "r U R' U' r' F R F'"},
   Al{"case 25, Bowtie", "F' r U R' U' r' F R"}, Al{"case 26, Antisune", "R U2 R' U' R U' R'"},
   Al{"case 27, Sune", "R U R' U R U2 R'"}, Al{"case 28", "r U R' U' r' R U R U' R'"},
   Al{"case 29", "R U R' U' R U' R' F' U' F R U R'"}, Al{"case 30", "F R' F R2 U' R' U' R U R' F2"},
   Al{"case 31", "R' U' F U R U' R' F' R"}, Al{"case 32", "L U F' U' L' U L F L'"},
   Al{"case 33", "R U R' U' R' F R F'"}, Al{"case 34", "R U R2 U' R' F R U R U' F'"},
   Al{"case 35", "R U2 R2 F R F' R U2 R'"}, Al{"case 36", "L' U' L U' L' U L U L F' L' F"},
   Al{"case 37", "F R' F' R U R U' R'"}, Al{"case 38", "R U R' U R U' R' U' R' F R F'"},
   Al{"case 39", "L F' L' U' L U F U' L'"}, Al{"case 40", "R' F R U R' U' F' U R"},
   Al{"case 41", "R U R' U R U2 R' F R U R' U' F'"}, Al{"case 42", "R' U' R U' R' U2 R F R U R' U' F'"},
   Al{"case 43", "F' U' L' U L F"}, Al{"case 44", "F U R U' R' F'"},
   Al{"case 45", "F R U R' U' F'"}, Al{"case 46", "R' U' R' F R F' U R"},
   Al{"case 47", "R' U' R' F R F' R' F R F' U R"}, Al{"case 48", "F R U R' U' R U R' U' F'"},
   Al{"case 49", "r U' r2 U r2 U r2 U' r"}, Al{"case 50", "r' U r2 U' r2 U' r2 U r'"},
   Al{"case 51", "F U R U' R' U R U' R' F'"}, Al{"case 52", "R U R' U R U' B U' B' R'"},
   Al{"case 53", "l' U2 L U L' U' L U L' U l"}, Al{"case 54", "r U2 R' U' R U R' U' R U' r'"},
   Al{"case 55", "R' F R U R U' R2 F' R2 U' R' U R U R'"}, Al{"case 56", "r' U' r U' R' U R U' R' U R r' U r"},
   Al{"case 57", "R U R' U' M' U R U' r'"}]

def wy.pll() -> List<&2, Al>:
  [Al{"Aa perm", "x L2 D2 L' U' L D2 L' U L'"}, Al{"Ab perm", "x' L2 D2 L U L' D2 L U' L"},
   Al{"E perm", "x' L' U L D' L' U' L D L' U' L D' L' U L D"}, Al{"F perm", "R' U' F' R U R' U' R' F R2 U' R' U' R U R' U R"},
   Al{"Ga perm", "R2 U R' U R' U' R U' R2 U' D R' U R D'"}, Al{"Gb perm", "R' U' R U D' R2 U R' U R U' R U' R2 D"},
   Al{"Gc perm", "R2 U' R U' R U R' U R2 U D' R U' R' D"}, Al{"Gd perm", "R U R' U' D R2 U' R U' R' U R' U R2 D'"},
   Al{"H perm", "M2 U M2 U2 M2 U M2"}, Al{"Ja perm", "x R2 F R F' R U2 r' U r U2"},
   Al{"Jb perm", "R U R' F' R U R' U' R' F R2 U' R'"}, Al{"Na perm", "R U R' U R U R' F' R U R' U' R' F R2 U' R' U2 R U' R'"},
   Al{"Nb perm", "R' U R U' R' F' U' F R U R' F R' F' R U' R"}, Al{"Ra perm", "R U' R' U' R U R D R' U' R D' R' U2 R'"},
   Al{"Rb perm", "R2 F R U R U' R' F' R U2 R' U2 R"}, Al{"T perm", "R U R' U' R' F R2 U' R' U' R U R' F'"},
   Al{"Ua perm", "M2 U M U2 M' U M2"}, Al{"Ub perm", "M2 U' M U2 M' U' M2"},
   Al{"V perm", "R' U R' U' y R' F' R2 U' R' U R' F R F"}, Al{"Y perm", "F R U' R' U' R U R' F' R U R' U' R' F R F'"},
   Al{"Z perm", "M' U M2 U M2 U M' U2 M2 U'"}]

# 2-look OLL: the edges, then the corners
def wy.oll2e() -> List<&2, Al>:
  [Al{"Line", "F R U R' U' F'"}, Al{"L shape", "f R U R' U' f'"}, Al{"Dot", "F R U R' U' F' f R U R' U' f'"}]

def wy.oll2c() -> List<&2, Al>:
  [Al{"Sune", "R U R' U R U2 R'"}, Al{"Antisune", "R U2 R' U' R U' R'"}, Al{"H", "R U R' U R U' R' U R U2 R'"},
   Al{"Pi", "R U2 R2 U' R2 U' R2 U2 R"}, Al{"Headlights", "R2 D R' U2 R D' R' U2 R'"},
   Al{"T", "r U R' U' r' F R F'"}, Al{"Bowtie", "F R' F' r U R U' r'"}]

# 2-look PLL: the corners, then the edges
def wy.pll2c() -> List<&2, Al>:
  [Al{"Headlights (T perm)", "R U R' U' R' F R2 U' R' U' R U R' F'"}, Al{"Diagonal (Y perm)", "F R U' R' U' R U R' F' R U R' U' R' F R F'"}]

def wy.pll2e() -> List<&2, Al>:
  [Al{"Ua perm", "M2 U M U2 M' U M2"}, Al{"Ub perm", "M2 U' M U2 M' U' M2"},
   Al{"H perm", "M2 U M2 U2 M2 U M2"}, Al{"Z perm", "M' U M2 U M2 U M' U2 M2 U'"}]

# The beginner's: a bottom corner from above its slot (as often as it takes),
# a middle edge from the top to the right or the left, the top's cross, its
# edges, its corners to their places, then each turned (the bottom layers
# come back once all four are)
def wy.b.corner() -> String:
  "R U R' U'"

def wy.b.edges() -> List<&2, Al>:
  [Al{"Edge to the right", "U R U' R' U' F' U F"}, Al{"Edge to the left", "U' L' U L U F U' F'"}]

def wy.b.cross() -> List<&2, Al>:
  [Al{"F R U R' U' F'", "F R U R' U' F'"}]

def wy.b.tope() -> List<&2, Al>:
  [Al{"R U R' U R U2 R' U", "R U R' U R U2 R' U"}]

def wy.b.topc() -> List<&2, Al>:
  [Al{"U R U' L' U R' U' L", "U R U' L' U R' U' L"}]

# Macros: what a step may do, each as one element of the cube's group
# --------------------------------------------------------------------

type Mc is Data:
  Mc{+name: String, +ms: List<&2, U32>, +c: C.Cube, +n: U32, +u: Bool}

def wy.mc(+name: String, +ms: List<&2, U32>, +u: Bool) -> Mc:
  Mc{name, ms, C.cube.apply(ms, C.cube.solved()), wy.len(ms), u}

def wy.mc.name(+m: Mc) -> String:
  match m:
    case Mc{+name, +ms, +c, +n, +u}:
      name

def wy.mc.ms(+m: Mc) -> List<&2, U32>:
  match m:
    case Mc{+name, +ms, +c, +n, +u}:
      ms

def wy.mc.c(+m: Mc) -> C.Cube:
  match m:
    case Mc{+name, +ms, +c, +n, +u}:
      c

def wy.mc.n(+m: Mc) -> U32:
  match m:
    case Mc{+name, +ms, +c, +n, +u}:
      n

def wy.mc.u(+m: Mc) -> Bool:
  match m:
    case Mc{+name, +ms, +c, +n, +u}:
      u

# moves done from another side: each face named as o names it
def wy.relabel(ms: List<&2, U32>, +o: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+m, t}:
      U32.add(U32.mul(C.cube.at(o, U32.div(m, 3)), 3), U32.mod(m, 3)) <> wy.relabel(t, o)

# the cube turned j quarter turns as U turns: the faces at each place
def wy.side(+j: U32) -> List<&2, U32>:
  wy.rot(U32.to_nat(j), 1, [0, 1, 2, 3, 4, 5])

def wy.sides(+name: String, +ms: List<&2, U32>) -> List<&2, Mc>:
  [wy.mc(name, ms, False{}), wy.mc(name, wy.relabel(ms, wy.side(1)), False{}),
   wy.mc(name, wy.relabel(ms, wy.side(2)), False{}), wy.mc(name, wy.relabel(ms, wy.side(3)), False{})]

def wy.mcs1(+a: Al) -> List<&2, Mc>:
  match a:
    case Al{+name, +nt}:
      wy.sides(name, wy.nt.ms(nt))

# each algorithm, from each of the four sides
def wy.mcs(als: List<&2, Al>) -> List<&2, Mc>:
  match als:
    case Nil{}:
      Nil{}
    case Con{+a, rest}:
      List.append(&2, Mc, wy.mcs1(a), wy.mcs(rest))

# the top turned
def wy.us() -> List<&2, Mc>:
  [wy.mc("U", [0], True{}), wy.mc("U2", [1], True{}), wy.mc("U'", [2], True{})]

def wy.rep(n: Nat, +ms: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      List.append(&2, U32, ms, wy.rep(p, ms))

# R U R' U' once to five times, above each slot
def wy.b.corners() -> List<&2, Mc>:
  +ms = wy.nt.ms(wy.b.corner())
  List.concat(&2, Mc, [wy.sides("R U R' U'", ms), wy.sides("R U R' U' x2", wy.rep(2n, ms)), wy.sides("R U R' U' x3", wy.rep(3n, ms)),
    wy.sides("R U R' U' x4", wy.rep(4n, ms)), wy.sides("R U R' U' x5", wy.rep(5n, ms))])

# Goals on the whole cube
# -----------------------
#
# A goal is a list of codes, each one thing that must hold: kind * 32 + p,
# p a corner's place (0..7) or 8 + an edge's (8..19); kind 0 the piece
# there is home (and turned right), 1 only turned right, 2 only home (a
# corner, turned any way).

def wy.ok1(+c: C.Cube, +code: U32) -> Bool:
  match c:
    case C.Cube{+cp, +co, +ep, +eo}:
      +k = U32.shrn(code, 5n)
      +p = U32.and(code, 31)
      +isc = U32.is_lt(p, 8)
      +i = Bool.pick(U32, isc, p, U32.sub(p, 8))
      +pl = Bool.pick(Bool, isc, U32.is_eq(C.cube.at(cp, i), i), U32.is_eq(C.cube.at(ep, i), i))
      +oz = U32.is_zero(Bool.pick(U32, isc, C.cube.at(co, i), C.cube.at(eo, i)))
      Bool.pick(Bool, U32.is_eq(k, 0), Bool.and(pl, oz), Bool.pick(Bool, U32.is_eq(k, 1), oz, pl))

def wy.oks(+c: C.Cube, ks: List<&2, U32>) -> Bool:
  match ks:
    case Nil{}:
      True{}
    case Con{+k, t}:
      Bool.and(wy.ok1(c, k), wy.oks(c, t))

def wy.anyok(+c: C.Cube, gs: List<&2, List<&2, U32>>) -> Bool:
  match gs:
    case Nil{}:
      False{}
    case Con{+g, t}:
      Bool.or(wy.oks(c, g), wy.anyok(c, t))

# all of must, and all of one of any (if any has any)
type Gl is Data:
  Gl{+must: List<&2, U32>, +any: List<&2, List<&2, U32>>}

def wy.goal(+c: C.Cube, +g: Gl) -> Bool:
  match g:
    case Gl{+must, +any}:
      Bool.and(wy.oks(c, must), Bool.or(List.is_empty(&2, List<&2, U32>, any), wy.anyok(c, any)))

def wy.k.cross() -> List<&2, U32>:
  [12, 13, 14, 15]

# the first two layers: the bottom corners, the bottom and middle edges
def wy.k.f2l() -> List<&2, U32>:
  [4, 5, 6, 7, 12, 13, 14, 15, 16, 17, 18, 19]

# the top: its edges turned right, its corners; its edges home, its corners;
# its corners in their places
def wy.k.eo() -> List<&2, U32>:
  [40, 41, 42, 43]

def wy.k.co() -> List<&2, U32>:
  [32, 33, 34, 35]

def wy.k.le() -> List<&2, U32>:
  [8, 9, 10, 11]

def wy.k.lc() -> List<&2, U32>:
  [0, 1, 2, 3]

def wy.k.cpl() -> List<&2, U32>:
  [64, 65, 66, 67]

def wy.k.all() -> List<&2, U32>:
  List.concat(&2, U32, [wy.k.f2l(), wy.k.le(), wy.k.lc()])

def wy.cat(+a: List<&2, U32>, +b: List<&2, U32>) -> List<&2, U32>:
  List.append(&2, U32, a, b)

# The search over macros
# ----------------------
#
# Every sequence of macros, up to d of them, no top turn right after another:
# the one with the fewest moves that reaches the goal (bx: the best so far;
# n 255 while there is none). A branch stops once it cannot beat bx.

type Bx is Data:
  Bx{+n: U32, +path: List<&2, Mc>}

def wy.bx.n(+b: Bx) -> U32:
  match b:
    case Bx{+n, +path}:
      n

def wy.bx.path(+b: Bx) -> List<&2, Mc>:
  match b:
    case Bx{+n, +path}:
      path

def wy.md.hit(h: Bool, +bx: Bx, +n: U32, +p: List<&2, Mc>) -> Bx:
  match h:
    case True{}:
      Bx{n, p}
    case False{}:
      bx

def wy.md(+d: Nat, ks: List<&2, Mc>, +c: C.Cube, +cost: U32, +path: List<&2, Mc>, +lu: Bool,
  +all: List<&2, Mc>, +g: Gl, +bx: Bx) -> Bx:
  match d ks:
    case 0n _:
      bx
    case 1n+dq Nil{}:
      bx
    case 1n+dq Con{+k, rest}:
      +skip = Bool.and(lu, wy.mc.u(k))
      +c2 = C.cube.mul(c, wy.mc.c(k))
      +cost2 = U32.add(cost, wy.mc.n(k))
      +p2 : List<&2, Mc> = k <> path
      +bx2 = wy.md.hit(Bool.and(Bool.not(skip), Bool.and(U32.is_lt(cost2, wy.bx.n(bx)), wy.goal(c2, g))), bx, cost2, p2)
      +deeper = Bool.and(Bool.not(skip), U32.is_lt(U32.add(cost2, 1), wy.bx.n(bx2)))
      wy.md(d, rest, c, cost, path, lu, all, g,
        wy.md(dq, Bool.pick(List<&2, Mc>, deeper, all, Nil{}), c2, cost2, p2, wy.mc.u(k), all, g, bx2))

# one macro, then two, ...: the short ones first, so the bound is tight early
def wy.mdi(ds: List<&2, Nat>, +c: C.Cube, +all: List<&2, Mc>, +g: Gl, +bx: Bx) -> Bx:
  match ds:
    case Nil{}:
      bx
    case Con{+d, rest}:
      wy.mdi(rest, c, all, g, wy.md(d, all, c, 0, [], False{}, all, g, bx))

def wy.path.ms(ps: List<&2, Mc>) -> List<&2, U32>:
  match ps:
    case Nil{}:
      Nil{}
    case Con{+p, t}:
      List.append(&2, U32, wy.mc.ms(p), wy.path.ms(t))

def wy.path.names(ps: List<&2, Mc>) -> List<&2, String>:
  match ps:
    case Nil{}:
      Nil{}
    case Con{+p, t}:
      +rest = wy.path.names(t)
      Bool.pick(List<&2, String>, wy.mc.u(p), rest, wy.mc.name(p) <> rest)

def wy.bx.moves(+b: Bx) -> List<&2, U32>:
  wy.path.ms(List.reverse(&2, Mc, wy.bx.path(b)))

def wy.bx.note(+b: Bx) -> String:
  String.join(wy.path.names(List.reverse(&2, Mc, wy.bx.path(b))), " + ")

def wy.bx0(+c: C.Cube, +g: Gl) -> Bx:
  Bx{Bool.pick(U32, wy.goal(c, g), 0, 255), []}

# The beginner's last step: each top corner turned at the front right, by
# R' D' R D twice (or four times: the other way), then the top turned to
# bring the next; the bottom layers are back once all four are
def wy.tw.pick(+c: C.Cube) -> List<&2, U32>:
  +t2 = wy.rep(2n, wy.nt.ms("R' D' R D"))
  +t4 = wy.rep(4n, wy.nt.ms("R' D' R D"))
  Bool.pick(List<&2, U32>, wy.ok1(c, 32), [], Bool.pick(List<&2, U32>, wy.ok1(C.cube.apply(t2, c), 32), t2, t4))

def wy.tw(n: Nat, +c: C.Cube, +acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      acc
    case 1n+p:
      +ms = List.append(&2, U32, wy.tw.pick(c), [0])
      wy.tw(p, C.cube.apply(ms, c), List.append(&2, U32, acc, ms))

# Ways
# ----

# A step done: what it is called, the algorithms it used, its moves
type Sr is Data:
  Sr{+label: String, +note: String, +ms: List<&2, U32>}

# A way under way: the array, the cube, its steps so far (last first),
# whether each reached its goal, and which candidate the last step did
type Mr is Type:
  Mr{t: Array<U32>, +c: C.Cube, +out: List<&2, Sr>, +ok: Bool, +last: U32}

def wy.fresh(m: Mr) -> Mr:
  match m:
    case Mr{t, +c, +out, +ok, +last}:
      Mr{t, c, out, ok, 99}

# A step of one of four: kind 0 a cross edge (DR DF DL DB: 0..3), 1 a slot's
# pair, 2 the whole cross (one candidate, 0), 3 a bottom corner, 4 a middle
# edge (by slot)
def wy.kc(+kind: U32, +q: U32) -> List<&2, U32>:
  Bool.pick(List<&2, U32>, U32.is_eq(kind, 0), [U32.add(12, q)],
    Bool.pick(List<&2, U32>, U32.is_eq(kind, 1), [U32.add(4, q), U32.add(16, q)],
      Bool.pick(List<&2, U32>, U32.is_eq(kind, 2), wy.k.cross(),
        Bool.pick(List<&2, U32>, U32.is_eq(kind, 3), [U32.add(4, q)], [U32.add(16, q)]))))

def wy.first.home(+c: C.Cube, +kind: U32, qs: List<&2, U32>) -> U32:
  match qs:
    case Nil{}:
      99
    case Con{+q, t}:
      Bool.pick(U32, wy.oks(c, wy.kc(kind, q)), q, wy.first.home(c, kind, t))

def wy.slot.name(+q: U32) -> String:
  Maybe.default(&2, String, List.get(&2, String, ["front right", "front left", "back left", "back right"], U32.to_nat(q)), "?")

def wy.edge.name(+q: U32) -> String:
  Maybe.default(&2, String, List.get(&2, String, ["right", "front", "left", "back"], U32.to_nat(q)), "?")

def wy.label(+kind: U32, +q: U32) -> String:
  Bool.pick(String, U32.is_eq(kind, 0), "Cross: the " ++ wy.edge.name(q) ++ " edge",
    Bool.pick(String, U32.is_eq(kind, 1), "F2L: the " ++ wy.slot.name(q) ++ " pair",
      Bool.pick(String, U32.is_eq(kind, 2), "Cross",
        Bool.pick(String, U32.is_eq(kind, 3), "Bottom corner: " ++ wy.slot.name(q), "Middle edge: " ++ wy.slot.name(q)))))

def wy.rm(qs: List<&2, U32>, +x: U32) -> List<&2, U32>:
  match qs:
    case Nil{}:
      Nil{}
    case Con{+q, t}:
      +r = wy.rm(t, x)
      Bool.pick(List<&2, U32>, U32.is_eq(q, x), r, q <> r)

def wy.e1s(ds: List<&2, U32>) -> List<&2, Tb>:
  match ds:
    case Nil{}:
      Nil{}
    case Con{+d, t}:
      wy.e1(d) <> wy.e1s(t)

def wy.e2o(+a: U32, +b: U32) -> Tb:
  wy.e2(U32.min(a, b), U32.max(a, b))

def wy.e2r(+r: U32, ds: List<&2, U32>) -> List<&2, Tb>:
  match ds:
    case Nil{}:
      Nil{}
    case Con{+d, t}:
      wy.e2o(r, d) <> wy.e2r(r, t)

def wy.e2p(ds: List<&2, U32>) -> List<&2, Tb>:
  match ds:
    case Nil{}:
      Nil{}
    case Con{+d, +t}:
      List.append(&2, Tb, wy.e2r(d, t), wy.e2p(t))

def wy.any0(rs: List<&2, U32>, +done: List<&2, U32>) -> List<&2, List<&2, Tb>>:
  match rs:
    case Nil{}:
      Nil{}
    case Con{+r, t}:
      (wy.e1(r) <> wy.e2r(r, done)) <> wy.any0(t, done)

def wy.prss(ds: List<&2, U32>) -> List<&2, Tb>:
  match ds:
    case Nil{}:
      Nil{}
    case Con{+d, t}:
      List.append(&2, Tb, wy.prs(d), wy.prss(t))

def wy.any1(rs: List<&2, U32>) -> List<&2, List<&2, Tb>>:
  match rs:
    case Nil{}:
      Nil{}
    case Con{+r, t}:
      wy.prs(r) <> wy.any1(t)

# the search's goal for a step of kind 0, 1 or 2
def wy.sp.of(+kind: U32, +rem: List<&2, U32>, +done: List<&2, U32>) -> Sp:
  Bool.pick(Sp, U32.is_eq(kind, 0), Sp{List.append(&2, Tb, wy.e1s(done), wy.e2p(done)), wy.any0(rem, done)},
    Bool.pick(Sp, U32.is_eq(kind, 1), Sp{List.append(&2, Tb, wy.e3s(), wy.prss(done)), wy.any1(rem)},
      Sp{[], [wy.e3s()]}))

def wy.kcs(+kind: U32, qs: List<&2, U32>) -> List<&2, U32>:
  match qs:
    case Nil{}:
      Nil{}
    case Con{+q, t}:
      List.append(&2, U32, wy.kc(kind, q), wy.kcs(kind, t))

def wy.kca(+kind: U32, qs: List<&2, U32>) -> List<&2, List<&2, U32>>:
  match qs:
    case Nil{}:
      Nil{}
    case Con{+q, t}:
      wy.kc(kind, q) <> wy.kca(kind, t)

# the macros' goal for a step of kind 3 or 4: what is done stays done
def wy.gl.of(+kind: U32, +rem: List<&2, U32>, +done: List<&2, U32>) -> Gl:
  Gl{List.append(&2, U32, Bool.pick(List<&2, U32>, U32.is_eq(kind, 3), wy.k.cross(), wy.cat(wy.k.cross(), [4, 5, 6, 7])), wy.kcs(kind, done)),
     wy.kca(kind, rem)}

def wy.mcs.of(+kind: U32) -> List<&2, Mc>:
  List.append(&2, Mc, Bool.pick(List<&2, Mc>, U32.is_eq(kind, 3), wy.b.corners(), wy.mcs(wy.b.edges())), wy.us())

def wy.ida.fin(r: Array<U32> & Rs, +c: C.Cube, +out: List<&2, Sr>, +ok: Bool, +kind: U32, +rem: List<&2, U32>) -> Mr:
  (t, +res) = r
  +ms = wy.rs.ms(res)
  +c2 = C.cube.apply(ms, c)
  +q = wy.first.home(c2, kind, rem)
  Mr{t, c2, Sr{wy.label(kind, q), "", ms} <> out, Bool.and(ok, Bool.and(wy.rs.got(res), U32.is_lt(q, 4))), q}

# a step by searching (kinds 0 to 2), or by macros (3, 4)
def wy.step.any(byms: Bool, m: Mr, +kind: U32, +rem: List<&2, U32>, +done: List<&2, U32>) -> Mr:
  match byms m:
    case False{} Mr{t, +c, +out, +ok, +last}:
      wy.ida.fin(wy.search(t, wy.wheres(c, wy.homes()), wy.sp.of(kind, rem, done)), c, out, ok, kind, rem)
    case True{} Mr{t, +c, +out, +ok, +last}:
      +bx = wy.mdi([1n, 2n, 3n], c, wy.mcs.of(kind), wy.gl.of(kind, rem, done), wy.bx0(c, wy.gl.of(kind, rem, done)))
      +ms = wy.simp(wy.bx.moves(bx))
      +c2 = C.cube.apply(ms, c)
      +q = wy.first.home(c2, kind, rem)
      Mr{t, c2, Sr{wy.label(kind, q), wy.bx.note(bx), ms} <> out, Bool.and(ok, Bool.and(U32.is_lt(wy.bx.n(bx), 255), U32.is_lt(q, 4))), q}

# n steps of a kind, each one more of the candidates rem: the last one done
# (m's last, 99 at first) moves from rem to done before the next
def wy.loop(n: Nat, m: Mr, +kind: U32, +rem: List<&2, U32>, +done: List<&2, U32>) -> Mr:
  match n m:
    case 0n _:
      m
    case 1n+p Mr{t, +c, +out, +ok, +last}:
      +r2 = wy.rm(rem, last)
      +d2 = Bool.pick(List<&2, U32>, U32.is_lt(last, 4), last <> done, done)
      wy.loop(p, wy.step.any(U32.is_ge(kind, 3), Mr{t, c, out, ok, last}, kind, r2, d2), kind, r2, d2)

# a step by macros: the fewest moves to the goal g, with up to ds of them
def wy.mac(m: Mr, +mcs: List<&2, Mc>, +g: Gl, +ds: List<&2, Nat>, +label: String) -> Mr:
  match m:
    case Mr{t, +c, +out, +ok, +last}:
      +bx = wy.mdi(ds, c, mcs, g, wy.bx0(c, g))
      +ms = wy.simp(wy.bx.moves(bx))
      Mr{t, C.cube.apply(ms, c), Sr{label, wy.bx.note(bx), ms} <> out, Bool.and(ok, U32.is_lt(wy.bx.n(bx), 255)), last}

def wy.with.us(als: List<&2, Al>) -> List<&2, Mc>:
  List.append(&2, Mc, wy.mcs(als), wy.us())

def wy.b.twist(m: Mr) -> Mr:
  match m:
    case Mr{t, +c, +out, +ok, +last}:
      +tw = wy.tw(4n, c, [])
      +c2 = C.cube.apply(tw, c)
      +g : Gl = Gl{wy.k.all(), []}
      +auf = wy.bx.moves(wy.mdi([1n], c2, wy.us(), g, wy.bx0(c2, g)))
      +ms = wy.simp(List.append(&2, U32, tw, auf))
      Mr{t, C.cube.apply(ms, c), Sr{"Top corners turned", "R' D' R D", ms} <> out, ok, last}

# The beginner's way (layer by layer): the cross an edge at a time, the bottom
# corners, the middle edges, then the top: its cross, its edges, its corners
# to their places, each turned
def wy.beginner(m: Mr) -> Mr:
  +f2l = wy.k.f2l()
  +eo = wy.cat(f2l, wy.k.eo())
  +le = wy.cat(eo, wy.k.le())
  wy.b.twist(
    wy.mac(
      wy.mac(
        wy.mac(
          wy.fresh(wy.loop(4n, wy.fresh(wy.loop(4n, wy.fresh(wy.loop(4n, m, 0, [0, 1, 2, 3], [])), 3, [0, 1, 2, 3], [])), 4, [0, 1, 2, 3], [])),
          wy.with.us(wy.b.cross()), Gl{eo, []}, [1n, 2n, 3n], "Top cross"),
        wy.with.us(wy.b.tope()), Gl{le, []}, [1n, 2n, 3n, 4n], "Top edges"),
      wy.with.us(wy.b.topc()), Gl{wy.cat(le, wy.k.cpl()), []}, [1n, 2n, 3n], "Top corners to their places"))

# CFOP's first two layers: the cross, then the pairs, each pair the one with
# the fewest moves of those left
def wy.f2l(m: Mr) -> Mr:
  wy.loop(4n, wy.fresh(wy.loop(1n, m, 2, [0], [])), 1, [0, 1, 2, 3], [])

# its last layer: OLL then PLL, one algorithm each
def wy.ll.full(m: Mr) -> Mr:
  +oc = List.concat(&2, U32, [wy.k.f2l(), wy.k.eo(), wy.k.co()])
  wy.mac(wy.mac(m, wy.mcs(wy.oll()), Gl{oc, []}, [1n], "OLL"), wy.with.us(wy.pll()), Gl{wy.k.all(), []}, [1n, 2n], "PLL")

# or in four looks: OLL's edges, its corners; PLL's corners, its edges
def wy.ll.simple(m: Mr) -> Mr:
  +eo = wy.cat(wy.k.f2l(), wy.k.eo())
  +oc = wy.cat(eo, wy.k.co())
  wy.mac(
    wy.mac(
      wy.mac(
        wy.mac(m, wy.with.us(wy.oll2e()), Gl{eo, []}, [1n, 2n], "OLL: the edges"),
        wy.with.us(wy.oll2c()), Gl{oc, []}, [1n, 2n], "OLL: the corners"),
      wy.with.us(wy.pll2c()), Gl{wy.cat(oc, wy.k.lc()), []}, [1n, 2n, 3n], "PLL: the corners"),
    wy.with.us(wy.pll2e()), Gl{wy.k.all(), []}, [1n, 2n, 3n], "PLL: the edges")

# The answer, as lines: "W|id|ok" (or "no": a step missed its goal, which
# would be a bug), then each step's "label|algorithms|moves" (moves as
# numbers, "3.10.17")
def wy.sr.line(+s: Sr) -> String:
  match s:
    case Sr{+label, +note, +ms}:
      "\n" ++ label ++ "|" ++ note ++ "|" ++ C.cube.nums(ms)

def wy.sr.lines(ss: List<&2, Sr>) -> String:
  match ss:
    case Nil{}:
      ""
    case Con{+s, t}:
      wy.sr.line(s) ++ wy.sr.lines(t)

def wy.out(+id: U32, m: Mr) -> Array<U32> & String:
  match m:
    case Mr{t, +c, +out, +ok, +last}:
      (t, "W|" ++ U32.show(id) ++ "|" ++ Bool.pick(String, Bool.and(ok, C.cube.is_solved(c)), "ok", "no") ++ wy.sr.lines(List.reverse(&2, Sr, out)))

def wy.run5(r: Array<U32> & String, +s1: String, +sb: String) -> Array<U32> & String:
  (t, +s2) = r
  (t, s1 ++ "\n" ++ s2 ++ "\n" ++ sb)

def wy.run4(r: Array<U32> & String, +c: C.Cube, +out: List<&2, Sr>, +ok: Bool, +sb: String) -> Array<U32> & String:
  (t, +s1) = r
  wy.run5(wy.out(2, wy.ll.simple(Mr{t, c, out, ok, 99})), s1, sb)

def wy.run3(m: Mr, +sb: String) -> Array<U32> & String:
  match m:
    case Mr{t, +c, +out, +ok, +last}:
      wy.run4(wy.out(1, wy.ll.full(Mr{t, c, out, ok, 99})), c, out, ok, sb)

def wy.run2(r: Array<U32> & String, +c: C.Cube) -> Array<U32> & String:
  (t, +sb) = r
  wy.run3(wy.f2l(Mr{t, c, [], True{}, 99}), sb)

# Every way for the cube the moves pos make (t: wy.tables()): CFOP (1), CFOP
# with a four-look last layer (2), the beginner's (3), each way's lines
# after the one before
def wy.run(t: Array<U32>, +pos: List<&2, U32>) -> Array<U32> & String:
  +c = C.cube.apply(pos, C.cube.solved())
  wy.run2(wy.out(3, wy.beginner(Mr{t, c, [], True{}, 99})), c)

# the same, for moves as numbers ("3.10.17"): what the page's worker asks
def wy.ways(t: Array<U32>, +s: String) -> Array<U32> & String:
  wy.run(t, Maybe.default(&2, List<&2, U32>, C.cube.read(s), []))

# For the laws (ALGS.bend)
# ------------------------

# whether an algorithm reads, and done on a solved cube keeps the codes ks
def wy.keeps1(+a: Al, +ks: List<&2, U32>) -> Bool:
  match a:
    case Al{+name, +nt}:
      +n = wy.nt(nt)
      Bool.and(wy.nt.ok(n), wy.oks(C.cube.apply(wy.nt.of(n), C.cube.solved()), ks))

def wy.keeps(als: List<&2, Al>, +ks: List<&2, U32>) -> Bool:
  match als:
    case Nil{}:
      True{}
    case Con{+a, t}:
      Bool.and(wy.keeps1(a, ks), wy.keeps(t, ks))

# the twist of the corner at the front right of the top (place URF)
def wy.co0(+c: C.Cube) -> U32:
  match c:
    case C.Cube{+cp, +co, +ep, +eo}:
      C.cube.at(co, 0)
