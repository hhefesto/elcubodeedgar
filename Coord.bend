import Base
import ./Cube.bend as C

# Coordinates: a cube state as a few numbers, so a move is a table lookup and
# a distance bound is one (Korf's pattern databases, 1997).
#
#   corners:  cp, the rank of the corner permutation (0..40319), and tw, the
#             twist of the first seven corners in base 3 (0..2186); together
#             cp * 2187 + tw (0..88179839): the corners exactly
#   edges:    a set of six edges (A: UR UF UL UB DR DF; B: DL DB FR FL BL BR)
#             as ar, where the six are (their places' arrangement, 0..665279),
#             and fl, their flips (six bits); together ar * 64 + fl
#
# A state is solved iff its three distances (corners, A, B) are 0: the three
# coordinates then are the solved ones, and they say where every piece is.
# Each distance bound is a true distance of a part of the cube, so never more
# than the cube's own: IDA* with their maximum finds a shortest solution.
#
# Every def is prefixed `co.`.

# Lists
# -----

# how many of ys are below x
def co.less(+x: U32, ys: List<&2, U32>) -> U32:
  match ys:
    case Nil{}:
      0
    case Con{+y, t}:
      U32.add(Bool.to_u32(U32.is_lt(y, x)), co.less(x, t))

# where x is in xs (from i), or 255
def co.index(+x: U32, xs: List<&2, U32>, +i: U32) -> U32:
  match xs:
    case Nil{}:
      255
    case Con{+y, t}:
      Bool.pick(U32, U32.is_eq(x, y), i, co.index(x, t, U32.add(i, 1)))

# xs without its k-th
def co.remove(xs: List<&2, U32>, +k: U32) -> List<&2, U32>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+y, +t}:
      Bool.pick(List<&2, U32>, U32.is_zero(k), t, y <> co.remove(t, U32.sub(k, 1)))

def co.range.go(n: Nat, +i: U32) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      i <> co.range.go(p, U32.add(i, 1))

# [0, 1, .., n - 1]
def co.range(n: Nat) -> List<&2, U32>:
  co.range.go(n, 0)

def co.fact(+n: Nat) -> U32:
  match n:
    case 0n:
      1
    case 1n+p:
      U32.mul(U32.add(U32.from_nat(p), 1), co.fact(p))

# Permutations, by rank (Lehmer's code)
# -------------------------------------

# sum of c_i * (n - 1 - i)!, c_i how many after the i-th are below it
def co.rank(p: List<&2, U32>) -> U32:
  match p:
    case Nil{}:
      0
    case Con{+x, +t}:
      U32.add(U32.mul(co.less(x, t), co.fact(List.length(&2, U32, t))), co.rank(t))

# the permutation of avail (n of them) with rank r
def co.unrank(+n: Nat, +r: U32, +avail: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      +f = co.fact(p)
      +d = U32.div(r, f)
      C.cube.at(avail, d) <> co.unrank(p, U32.mod(r, f), co.remove(avail, d))

# The twist: co[0..6] in base 3 (co[7] follows: the sum is 0 mod 3)
def co.twist.go(n: Nat, co: List<&2, U32>, +acc: U32) -> U32:
  match n co:
    case 1n+p Con{+x, t}:
      co.twist.go(p, t, U32.add(U32.mul(acc, 3), x))
    case _ _:
      acc

def co.twist(co: List<&2, U32>) -> U32:
  co.twist.go(7n, co, 0)

def co.untwist.go(n: Nat, +t: U32, acc: List<&2, U32>, +sum: U32) -> List<&2, U32>:
  match n:
    case 0n:
      List.append(&2, U32, acc, [U32.mod(U32.sub(3, U32.mod(sum, 3)), 3)])
    case 1n+p:
      +x = U32.mod(t, 3)
      co.untwist.go(p, U32.div(t, 3), x <> acc, U32.add(sum, x))

def co.untwist(+t: U32) -> List<&2, U32>:
  co.untwist.go(7n, t, Nil{}, 0)

# Six edges' places: their arrangement
# ------------------------------------

# the arrangement of places qs (distinct, of 0..11): digit k is q_k less how
# many before it are below it, in radix 12 - k: ((d0 * 11 + d1) * 10 + ..) * 7 + d5
def co.arr.go(qs: List<&2, U32>, +prev: List<&2, U32>, +k: U32, +acc: U32) -> U32:
  match qs:
    case Nil{}:
      acc
    case Con{+q, t}:
      co.arr.go(t, q <> prev, U32.add(k, 1), U32.add(U32.mul(acc, U32.sub(12, k)), U32.sub(q, co.less(q, prev))))

def co.arr(qs: List<&2, U32>) -> U32:
  co.arr.go(qs, Nil{}, 0, 0)

def co.unarr.digits(n: Nat, +a: U32, +rad: U32, acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      acc
    case 1n+p:
      co.unarr.digits(p, U32.div(a, rad), U32.add(rad, 1), U32.mod(a, rad) <> acc)

def co.unarr.places(ds: List<&2, U32>, +avail: List<&2, U32>) -> List<&2, U32>:
  match ds:
    case Nil{}:
      Nil{}
    case Con{+d, t}:
      C.cube.at(avail, d) <> co.unarr.places(t, co.remove(avail, d))

# the places of arrangement a
def co.unarr(+a: U32) -> List<&2, U32>:
  co.unarr.places(co.unarr.digits(6n, a, 7, Nil{}), co.range(12n))

# the places of pieces ps in a state's ep
def co.places(ps: List<&2, U32>, +ep: List<&2, U32>) -> List<&2, U32>:
  match ps:
    case Nil{}:
      Nil{}
    case Con{+x, t}:
      co.index(x, ep, 0) <> co.places(t, ep)

# the flips at places qs, bit k the k-th's
def co.flips(qs: List<&2, U32>, +eo: List<&2, U32>, +k: Nat) -> U32:
  match qs:
    case Nil{}:
      0
    case Con{+q, t}:
      U32.or(U32.shln(C.cube.at(eo, q), k), co.flips(t, eo, 1n+k))

def co.set.A() -> List<&2, U32>:
  [0, 1, 2, 3, 4, 5]

def co.set.B() -> List<&2, U32>:
  [6, 7, 8, 9, 10, 11]

# A state's coordinates
# ---------------------

type Coords is Data:
  Coords{+cp: U32, +tw: U32, +a: U32, +fa: U32, +b: U32, +fb: U32}

def co.edges(ps: List<&2, U32>, +ep: List<&2, U32>, +eo: List<&2, U32>) -> U32 & U32:
  +qs = co.places(ps, ep)
  (co.arr(qs), co.flips(qs, eo, 0n))

def co.of.mk(+cp: U32, +tw: U32, ea: U32 & U32, eb: U32 & U32) -> Coords:
  (a, fa) = ea
  (b, fb) = eb
  Coords{cp, tw, a, fa, b, fb}

def co.of(+c: C.Cube) -> Coords:
  match c:
    case C.Cube{cp, co, ep, eo}:
      co.of.mk(co.rank(cp), co.twist(co), co.edges(co.set.A(), ep, eo), co.edges(co.set.B(), ep, eo))

# The tables, in one array
# ------------------------
#
# T (2^26 U32s, 256 MB) holds, at
#   co.T.cp():  cp's moves, cp * 18 + m           (725760)
#   co.T.tw():  tw's moves, tw * 18 + m           (39366)
#   co.T.e():   an arrangement's moves, a * 18 + m: the new arrangement, and
#               the six edges' flips (to xor) above bit 20  (11975040)
#   co.T.pc():  the corners' distances, 4 bits each, 8 a word  (11022480)
#   co.T.pa(), co.T.pb(): A's and B's distances, 4 bits each  (5322240 each)
# A distance of 15 is one not found yet.

def co.T.cp() -> U32:
  0

def co.T.tw() -> U32:
  725760

def co.T.e() -> U32:
  1048576

def co.T.pc() -> U32:
  13107200

def co.T.pa() -> U32:
  24129680

def co.T.pb() -> U32:
  29451920

def co.n.pc() -> U32:
  88179840

def co.n.pe() -> U32:
  42577920

# the 18 moves as states, once
def co.moves.go(n: Nat, +m: U32) -> List<&2, C.Cube>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      C.cube.move(m) <> co.moves.go(p, U32.add(m, 1))

def co.moves() -> List<&2, C.Cube>:
  co.moves.go(18n, 0)

# write vs from T[at] on
def co.write(vs: List<&2, U32>, t: Array<U32>, +at: U32) -> Array<U32>:
  match vs:
    case Nil{}:
      t
    case Con{+v, r}:
      co.write(r, Array.set(U32, t, at, v), U32.add(at, 1))

# cp's 18 moves
def co.cp.row(ms: List<&2, C.Cube>, +p: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+m, t}:
      match m:
        case C.Cube{mcp, mco, mep, meo}:
          co.rank(C.cube.mul.p(p, mcp)) <> co.cp.row(t, p)

def co.tw.row(ms: List<&2, C.Cube>, +o: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+m, t}:
      match m:
        case C.Cube{mcp, mco, mep, meo}:
          co.twist(C.cube.mul.o(o, mcp, mco, 3)) <> co.tw.row(t, o)

# Where a move takes an edge at place q, and whether it flips it there: the
# move's ep inverted, and its eo at the new place
def co.inv(+p: List<&2, U32>, qs: List<&2, U32>) -> List<&2, U32>:
  match qs:
    case Nil{}:
      Nil{}
    case Con{+q, t}:
      co.index(q, p, 0) <> co.inv(p, t)

type EMove is Data:
  EMove{+to: List<&2, U32>, +eo: List<&2, U32>}

def co.emoves.go(ms: List<&2, C.Cube>) -> List<&2, EMove>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+m, t}:
      match m:
        case C.Cube{mcp, mco, mep, meo}:
          EMove{co.inv(mep, co.range(12n)), meo} <> co.emoves.go(t)

def co.emoves() -> List<&2, EMove>:
  co.emoves.go(co.moves())

def co.e.to(qs: List<&2, U32>, +to: List<&2, U32>) -> List<&2, U32>:
  match qs:
    case Nil{}:
      Nil{}
    case Con{+q, t}:
      C.cube.at(to, q) <> co.e.to(t, to)

def co.e.one(+qs: List<&2, U32>, +m: EMove) -> U32:
  match m:
    case EMove{to, eo}:
      +nq = co.e.to(qs, to)
      U32.or(co.arr(nq), U32.shln(co.flips(nq, eo, 0n), 20n))

def co.e.row(ms: List<&2, EMove>, +qs: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+m, t}:
      co.e.one(qs, m) <> co.e.row(t, qs)

# rows for coordinates i.. (n of them) at T[off + i * 18]
def co.fill.cp(n: Nat, t: Array<U32>, +i: U32, +ms: List<&2, C.Cube>) -> Array<U32>:
  match n:
    case 0n:
      t
    case 1n+p:
      +row = co.cp.row(ms, co.unrank(8n, i, co.range(8n)))
      co.fill.cp(p, co.write(row, t, U32.add(co.T.cp(), U32.mul(i, 18))), U32.add(i, 1), ms)

def co.fill.tw(n: Nat, t: Array<U32>, +i: U32, +ms: List<&2, C.Cube>) -> Array<U32>:
  match n:
    case 0n:
      t
    case 1n+p:
      +row = co.tw.row(ms, co.untwist(i))
      co.fill.tw(p, co.write(row, t, U32.add(co.T.tw(), U32.mul(i, 18))), U32.add(i, 1), ms)

def co.fill.e(n: Nat, t: Array<U32>, +i: U32, +ms: List<&2, EMove>) -> Array<U32>:
  match n:
    case 0n:
      t
    case 1n+p:
      +row = co.e.row(ms, co.unarr(i))
      co.fill.e(p, co.write(row, t, U32.add(co.T.e(), U32.mul(i, 18))), U32.add(i, 1), ms)

# The move tables
def co.moves.fill(t: Array<U32>) -> Array<U32>:
  +ms = co.moves()
  t1 = co.fill.cp(40320n, t, 0, ms)
  t2 = co.fill.tw(2187n, t1, 0, ms)
  co.fill.e(665280n, t2, 0, co.emoves())

# Distances, 4 bits each
# ----------------------

def co.nib(+w: U32, +i: U32) -> U32:
  U32.and(U32.shrn(w, U32.to_nat(U32.mul(U32.and(i, 7), 4))), 15)

# w with entry i (of its 8) lowered from 15 to v, if it is 15; with 1 if it was
def co.lower(+w: U32, +i: U32, +v: U32) -> U32 & U32:
  +s = U32.to_nat(U32.mul(U32.and(i, 7), 4))
  +fresh = Bool.to_u32(U32.is_eq(U32.and(U32.shrn(w, s), 15), 15))
  (U32.sub(w, U32.shln(U32.mul(fresh, U32.sub(15, v)), s)), fresh)

# What a step of a breadth-first level is about to do
type BOp is Data:
  BWord{}
  BNib{}
  BMove{}
  BR1{}
  BR2{}
  BR3{}

# Which table: the corners (cp * 2187 + tw: two lookups), or a set of edges
# (ar * 64 + fl: one), and where its distances are
type Tab is Data:
  KC{}
  KE{+off: U32}

def co.kind.pdb(+k: Tab) -> U32:
  match k:
    case KC{}:
      co.T.pc()
    case KE{off}:
      off

def co.kind.words(+k: Tab) -> Nat:
  match k:
    case KC{}:
      U32.to_nat(U32.div(U32.add(co.n.pc(), 7), 8))
    case KE{off}:
      U32.to_nat(U32.div(U32.add(co.n.pe(), 7), 8))

# an entry's two parts: cp and tw, or ar and fl
def co.split.x(+k: Tab, +i: U32) -> U32:
  match k:
    case KC{}:
      U32.div(i, 2187)
    case KE{off}:
      U32.shrn(i, 6n)

def co.split.y(+k: Tab, +i: U32) -> U32:
  match k:
    case KC{}:
      U32.mod(i, 2187)
    case KE{off}:
      U32.and(i, 63)

# the first lookup of move m from an entry whose first part is x, and what reads it
def co.kind.at1(+k: Tab, +x: U32, +m: U32) -> U32:
  match k:
    case KC{}:
      U32.add(co.T.cp(), U32.add(U32.mul(x, 18), m))
    case KE{off}:
      U32.add(co.T.e(), U32.add(U32.mul(x, 18), m))

def co.kind.op1(+k: Tab) -> BOp:
  match k:
    case KC{}:
      BR1{}
    case KE{off}:
      BR2{}

# the new entry, from the last lookup v (and the corners' first, x2)
def co.kind.entry(+k: Tab, +x2: U32, +y: U32, +v: U32) -> U32:
  match k:
    case KC{}:
      U32.add(U32.mul(x2, 2187), v)
    case KE{off}:
      U32.add(U32.shln(U32.and(v, 1048575), 6n), U32.xor(y, U32.shrn(v, 20n)))

def co.lower.s(+i: U32) -> Nat:
  U32.to_nat(U32.mul(U32.and(i, 7), 4))

# 1 if entry i of w is unseen (15)
def co.lower.fresh(+w: U32, +i: U32) -> U32:
  Bool.to_u32(U32.is_eq(U32.and(U32.shrn(w, co.lower.s(i)), 15), 15))

# w with entry i lowered from 15 to v, if it is 15
def co.lower.w(+w: U32, +i: U32, +v: U32) -> U32:
  U32.sub(w, U32.shln(U32.mul(co.lower.fresh(w, i), U32.sub(15, v)), co.lower.s(i)))

# One level of a breadth-first search: every entry at distance d (from word
# wi on; wf words left) gives its moves' unseen entries d + 1. r is the array
# and the word last read: each step reads at most one word, and goes on as op
# says, ok saying whether the index it is about (j or m) is in range. Answers
# the array and how many entries were new.
#   w: the word; j: the entry in it; x, y: the entry's two parts
#   m: the move; x2: the corners' first lookup; ci: the new entry
def co.bfs(
  +wf: Nat, fuel: Nat, op: BOp, ok: Bool, r: Array<U32> & U32, +k: Tab, +d: U32, +wi: U32,
  +w: U32, +j: U32, +x: U32, +y: U32, +m: U32, +x2: U32, +ci: U32, +n: U32
) -> Array<U32> & U32:
  match wf fuel op ok:
    case 0n _ _ _:
      (t, v) = r
      (t, n)
    case 1n+wq 0n _ _:
      # out of fuel in a word: cannot happen (a word takes at most 1 + 8 * 74 + 1 steps)
      (t, v) = r
      +wn = U32.add(wi, 1)
      co.bfs(wq, 1023n, BWord{}, True{}, t[U32.add(co.kind.pdb(k), wn)], k, d, wn, 0, 0, 0, 0, 0, 0, 0, n)
    case 1n+wq 1n+fq BWord{} _:
      # a word read: its entries
      (t, +v) = r
      co.bfs(wf, fq, BNib{}, True{}, (t, 0), k, d, wi, v, 0, 0, 0, 0, 0, 0, n)
    case 1n+wq 1n+fq BNib{} False{}:
      # past the word's last entry: the next word
      (t, z) = r
      +wn = U32.add(wi, 1)
      co.bfs(wq, 1023n, BWord{}, True{}, t[U32.add(co.kind.pdb(k), wn)], k, d, wn, 0, 0, 0, 0, 0, 0, 0, n)
    case 1n+wq 1n+fq BNib{} True{}:
      # entry j: its moves if it is at distance d
      (t, z) = r
      +i = U32.add(U32.mul(wi, 8), j)
      co.bfs(wf, fq, BMove{}, U32.is_eq(co.nib(w, j), d), (t, 0), k, d, wi, w, j,
        co.split.x(k, i), co.split.y(k, i), 0, 0, 0, n)
    case 1n+wq 1n+fq BMove{} False{}:
      # past the last move: the next entry
      (t, z) = r
      +jn = U32.add(j, 1)
      co.bfs(wf, fq, BNib{}, U32.is_lt(jn, 8), (t, 0), k, d, wi, w, jn, 0, 0, 0, 0, 0, n)
    case 1n+wq 1n+fq BMove{} True{}:
      # move m: its first lookup
      (t, z) = r
      co.bfs(wf, fq, co.kind.op1(k), True{}, t[co.kind.at1(k, x, m)], k, d, wi, w, j, x, y, m, 0, 0, n)
    case 1n+wq 1n+fq BR1{} _:
      # the corners: cp's move read; now tw's
      (t, +v) = r
      co.bfs(wf, fq, BR2{}, True{}, t[U32.add(co.T.tw(), U32.add(U32.mul(y, 18), m))], k, d, wi, w, j, x, y, m, v, 0, n)
    case 1n+wq 1n+fq BR2{} _:
      # the last lookup read: the new entry, and its word
      (t, +v) = r
      +c = co.kind.entry(k, x2, y, v)
      co.bfs(wf, fq, BR3{}, True{}, t[U32.add(co.kind.pdb(k), U32.shrn(c, 3n))], k, d, wi, w, j, x, y, m, x2, c, n)
    case 1n+wq 1n+fq BR3{} _:
      # the new entry's word: d + 1 there if it was unseen
      (t, +v) = r
      t2 = Array.set(U32, t, U32.add(co.kind.pdb(k), U32.shrn(ci, 3n)), co.lower.w(v, ci, U32.add(d, 1)))
      +mn = U32.add(m, 1)
      co.bfs(wf, fq, BMove{}, U32.is_lt(mn, 18), (t2, 0), k, d, wi, w, j, x, y, mn, 0, 0, U32.add(n, co.lower.fresh(v, ci)))

# a level from the first word
def co.level(t: Array<U32>, +k: Tab, +d: U32) -> Array<U32> & U32:
  co.bfs(co.kind.words(k), 1023n, BWord{}, True{}, t[co.kind.pdb(k)], k, d, 0, 0, 0, 0, 0, 0, 0, 0, 0)
