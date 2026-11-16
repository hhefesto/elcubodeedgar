import Base
import ./Cube.bend as C
import ./Coord.bend as K
import ./Search.bend as S
import ./Kc.bend as T

# A short solution at once, not always the shortest: Kociemba's two-phase
# algorithm (1992). Phase 1 takes the cube into S, the cubes whose edges are
# unflipped, whose corners are untwisted, and whose U-D slice edges (FR FL BL
# BR) are home in order: Kc.bend's table is every cube's exact distance to S,
# so phase 1 never follows a move that cannot get there in time. Phase 2
# solves the cube from S with the moves that keep its edges unflipped and
# its corners untwisted (U, D, every turn; R2, L2, F2, B2), its bound the
# larger of two exact distances in that group: of the corners' places with
# the slice edges' order, and of the U and D edges' places with the slice
# edges' order. Many ways into S are tried, shortest first, each finished by
# the shortest phase 2 that makes the whole shorter than the best so far, up
# to tp.budget() of them.
#
# Every answer is a solution of the cube (the server checks it again with
# Cube.bend before it goes out); its length is an upper bound on the
# shortest, which the optimal search (Opt.bend) then needs only search below.
#
# The tables, in the solver's one array from tp.UDM() on (above Kc.bend's),
# made when the solver starts (tp.tables):
#   tp.UDM  the U and D edges' places (8! = 40320) under phase 2's 10 moves
#   tp.SPM  the slice edges' order (4! = 24) under them
#   tp.PC   at sp * 40320 + cp: the distance of the corners' places cp with
#           the slice's order sp, plus 1 (0: not found yet)
#   tp.PU   at sp * 40320 + ud: the same for the U and D edges' places
#
# Every def is prefixed `tp.`.

def tp.UDM() -> U32:
  920000000

def tp.SPM() -> U32:
  920500000

def tp.PC() -> U32:
  920600000

def tp.PU() -> U32:
  921600000

# entries in each of PC and PU: 24 * 40320
def tp.n2() -> U32:
  967680

# phase 2's moves, i = 0..9: U U2 U' D D2 D' R2 L2 F2 B2
def tp.mv(+i: U32) -> U32:
  Bool.pick(U32, U32.is_lt(i, 3), i,
    Bool.pick(U32, U32.is_lt(i, 6), U32.add(i, 6),
      Bool.pick(U32, U32.is_eq(i, 6), 4,
        Bool.pick(U32, U32.is_eq(i, 7), 13, Bool.pick(U32, U32.is_eq(i, 8), 7, 16)))))

# Phase 2's coordinates
# ---------------------

# xs, each less 8
def tp.sub8(xs: List<&2, U32>) -> List<&2, U32>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+x, t}:
      U32.sub(x, 8) <> tp.sub8(t)

def tp.add8(xs: List<&2, U32>) -> List<&2, U32>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+x, t}:
      U32.add(x, 8) <> tp.add8(t)

# the U and D edges' places: which of UR..DB is at each of places 0..7
def tp.ud.of(+ep: List<&2, U32>) -> U32:
  K.co.rank(List.take(&2, U32, ep, 8n))

# the slice edges' order: which of FR..BR is at each of places 8..11
def tp.sp.of(+ep: List<&2, U32>) -> U32:
  K.co.rank(tp.sub8(List.drop(&2, U32, ep, 8n)))

def tp.cp.of(+c: C.Cube) -> U32:
  match c:
    case C.Cube{cp, co, ep, eo}:
      K.co.rank(cp)

def tp.ep(+c: C.Cube) -> List<&2, U32>:
  match c:
    case C.Cube{cp, co, ep, eo}:
      ep

# a cube's ep with the U and D edges at ud, the slice's home; and the other way
def tp.ud.ep(+ud: U32) -> List<&2, U32>:
  List.append(&2, U32, K.co.unrank(8n, ud, K.co.range(8n)), [8, 9, 10, 11])

def tp.sp.ep(+sp: U32) -> List<&2, U32>:
  List.append(&2, U32, K.co.range(8n), tp.add8(K.co.unrank(4n, sp, K.co.range(4n))))

# phase 2's moves' ep, once
def tp.meps.go(n: Nat, +i: U32) -> List<&2, List<&2, U32>>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      tp.ep(C.cube.move(tp.mv(i))) <> tp.meps.go(p, U32.add(i, 1))

def tp.meps() -> List<&2, List<&2, U32>>:
  tp.meps.go(10n, 0)

# The move tables
# ---------------

def tp.udm.row(ms: List<&2, List<&2, U32>>, +ep: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+mep, t}:
      tp.ud.of(C.cube.mul.p(ep, mep)) <> tp.udm.row(t, ep)

def tp.spm.row(ms: List<&2, List<&2, U32>>, +ep: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+mep, t}:
      tp.sp.of(C.cube.mul.p(ep, mep)) <> tp.spm.row(t, ep)

def tp.fill.udm(n: Nat, t: Array<U32>, +ud: U32, +ms: List<&2, List<&2, U32>>) -> Array<U32>:
  match n:
    case 0n:
      t
    case 1n+p:
      +row = tp.udm.row(ms, tp.ud.ep(ud))
      tp.fill.udm(p, K.co.write(row, t, U32.add(tp.UDM(), U32.mul(ud, 10))), U32.add(ud, 1), ms)

def tp.fill.spm(n: Nat, t: Array<U32>, +sp: U32, +ms: List<&2, List<&2, U32>>) -> Array<U32>:
  match n:
    case 0n:
      t
    case 1n+p:
      +row = tp.spm.row(ms, tp.sp.ep(sp))
      tp.fill.spm(p, K.co.write(row, t, U32.add(tp.SPM(), U32.mul(sp, 10))), U32.add(sp, 1), ms)

# The distance tables, breadth first
# ----------------------------------

# which: the corners' places (their moves Coord.bend's, all 18), or the U and
# D edges' (tp.UDM)
type P2 is Data:
  PC{}
  PU{}

def tp.p2.at(+k: P2) -> U32:
  match k:
    case PC{}:
      tp.PC()
    case PU{}:
      tp.PU()

# where x's move i is
def tp.p2.xm(+k: P2, +x: U32, +i: U32) -> U32:
  match k:
    case PC{}:
      U32.add(K.co.T.cp(), U32.add(U32.mul(x, 18), tp.mv(i)))
    case PU{}:
      U32.add(tp.UDM(), U32.add(U32.mul(x, 10), i))

# what a step of a level is about to do
type BS is Data:
  BE{}
  BM{}
  BX{}
  BY{}
  BC{}

# One level of a breadth-first search, as Coord.bend's co.bfs (one read a
# step): every entry at distance d (its word d + 1), from entry e on (n left),
# gives its moves' unseen entries d + 1 (word d + 2). Answers how many were new.
#   BE: entry e read; BM: move i next (ok: i < 10, or e is at d); BX: x's
#   move read; BY: the slice's move read; BC: the child's entry read
def tp.bfs(
  +n: Nat, fuel: Nat, op: BS, ok: Bool, r: Array<U32> & U32, +k: P2, +d: U32,
  +e: U32, +x: U32, +sp: U32, +i: U32, +x2: U32, +c: U32, +cnt: U32
) -> Array<U32> & U32:
  match n fuel op ok:
    case 0n _ _ _:
      (t, v) = r
      (t, cnt)
    case 1n+nq 0n _ _:
      # out of fuel in an entry: cannot happen (an entry takes 2 + 10 * 4 steps)
      (t, v) = r
      +en = U32.add(e, 1)
      tp.bfs(nq, 63n, BE{}, True{}, t[U32.add(tp.p2.at(k), en)], k, d, en, 0, 0, 0, 0, 0, cnt)
    case 1n+nq 1n+fq BE{} _:
      (t, +v) = r
      tp.bfs(n, fq, BM{}, U32.is_eq(v, U32.add(d, 1)), (t, 0), k, d, e, U32.mod(e, 40320), U32.div(e, 40320), 0, 0, 0, cnt)
    case 1n+nq 1n+fq BM{} False{}:
      # the next entry
      (t, z) = r
      +en = U32.add(e, 1)
      tp.bfs(nq, 63n, BE{}, True{}, t[U32.add(tp.p2.at(k), en)], k, d, en, 0, 0, 0, 0, 0, cnt)
    case 1n+nq 1n+fq BM{} True{}:
      (t, z) = r
      tp.bfs(n, fq, BX{}, True{}, t[tp.p2.xm(k, x, i)], k, d, e, x, sp, i, 0, 0, cnt)
    case 1n+nq 1n+fq BX{} _:
      (t, +v) = r
      tp.bfs(n, fq, BY{}, True{}, t[U32.add(tp.SPM(), U32.add(U32.mul(sp, 10), i))], k, d, e, x, sp, i, v, 0, cnt)
    case 1n+nq 1n+fq BY{} _:
      (t, +v) = r
      +cc = U32.add(U32.mul(v, 40320), x2)
      tp.bfs(n, fq, BC{}, True{}, t[U32.add(tp.p2.at(k), cc)], k, d, e, x, sp, i, x2, cc, cnt)
    case 1n+nq 1n+fq BC{} _:
      (t, +v) = r
      +fresh = U32.is_zero(v)
      t2 = Array.set(U32, t, U32.add(tp.p2.at(k), c), Bool.pick(U32, fresh, U32.add(d, 2), v))
      +inx = U32.add(i, 1)
      tp.bfs(n, fq, BM{}, U32.is_lt(inx, 10), (t2, 0), k, d, e, x, sp, inx, 0, 0, U32.add(cnt, Bool.to_u32(fresh)))

def tp.level(t: Array<U32>, +k: P2, +d: U32) -> Array<U32> & U32:
  tp.bfs(U32.to_nat(tp.n2()), 63n, BE{}, True{}, t[tp.p2.at(k)], k, d, 0, 0, 0, 0, 0, 0, 0)

def tp.levels(n: Nat, r: Array<U32> & U32, +k: P2, +d: U32) -> Array<U32>:
  match n:
    case 0n:
      (t, v) = r
      t
    case 1n+q:
      (t, +c) = r
      tp.levels(q, tp.level(t, k, d), k, U32.add(d, 1))

# Phase 2's tables, in t beside Coord.bend's (whose corners' moves they use):
# the moves, then each distance table from solved (its entry 0, word 1)
def tp.tables(t: Array<U32>) -> Array<U32>:
  +ms = tp.meps()
  t1 = tp.fill.spm(24n, tp.fill.udm(40320n, t, 0, ms), 0, ms)
  t2 = Array.set(U32, Array.set(U32, t1, tp.PC(), 1), tp.PU(), 1)
  tp.levels(20n, (tp.levels(20n, (t2, 0), PC{}, 0), 0), PU{}, 0)

# Phase 2's search
# ----------------

# What a step is about to do (Search.bend's sr.go, for phase 2's coordinates)
type Z is Data:
  ZTry{}
  ZR1{}
  ZR2{}
  ZR3{}
  ZR4{}
  ZR5{}
  ZDec{}
  ZBack{}

# The search below a phase-2 node (cp, ud, sp), d moves left (bud: d as a
# U32), its moves phase 2's (move i is tp.mv(i)), Search.bend's rules kept
# (lf: the last move's face, also phase 1's last). hc: the child's corner
# entry, until its edges' is read.
def tp.go2(
  +d: Nat, fuel: Nat, op: Z, more: Bool, ok: Bool, cut: Bool, goal: Bool, c: S.Carry,
  +bud: U32, +cp: U32, +ud: U32, +sp: U32, +lf: U32, +path: List<&2, U32>, +i: U32,
  +cp2: U32, +ud2: U32, +sp2: U32, +hc: U32
) -> Array<U32> & S.Res:
  match d fuel op more ok cut goal c:
    case _ 0n _ _ _ _ _ _:
      S.sr.out(c)
    case _ 1n+fq ZTry{} False{} _ _ _ _:
      S.sr.out(c)
    case _ 1n+fq ZTry{} True{} False{} _ _ S.CW{r, +res}:
      +inx = U32.add(i, 1)
      tp.go2(d, fq, ZTry{}, Bool.and(U32.is_lt(inx, 10), Bool.not(S.sr.found(res))), S.sr.allowed(tp.mv(inx), lf), False{}, False{}, S.CW{r, res},
        bud, cp, ud, sp, lf, path, inx, 0, 0, 0, 0)
    case _ 1n+fq ZTry{} True{} True{} _ _ S.CW{r, +res}:
      (t, z) = r
      tp.go2(d, fq, ZR1{}, True{}, True{}, False{}, False{}, S.CW{t[U32.add(K.co.T.cp(), U32.add(U32.mul(cp, 18), tp.mv(i)))], res},
        bud, cp, ud, sp, lf, path, i, 0, 0, 0, 0)
    case _ 1n+fq ZR1{} _ _ _ _ S.CW{r, +res}:
      (t, +v) = r
      tp.go2(d, fq, ZR2{}, True{}, True{}, False{}, False{}, S.CW{t[U32.add(tp.UDM(), U32.add(U32.mul(ud, 10), i))], res},
        bud, cp, ud, sp, lf, path, i, v, 0, 0, 0)
    case _ 1n+fq ZR2{} _ _ _ _ S.CW{r, +res}:
      (t, +v) = r
      tp.go2(d, fq, ZR3{}, True{}, True{}, False{}, False{}, S.CW{t[U32.add(tp.SPM(), U32.add(U32.mul(sp, 10), i))], res},
        bud, cp, ud, sp, lf, path, i, cp2, v, 0, 0)
    case _ 1n+fq ZR3{} _ _ _ _ S.CW{r, +res}:
      (t, +v) = r
      tp.go2(d, fq, ZR4{}, True{}, True{}, False{}, False{}, S.CW{t[U32.add(tp.PC(), U32.add(U32.mul(v, 40320), cp2))], res},
        bud, cp, ud, sp, lf, path, i, cp2, ud2, v, 0)
    case _ 1n+fq ZR4{} _ _ _ _ S.CW{r, +res}:
      (t, +v) = r
      tp.go2(d, fq, ZR5{}, True{}, True{}, False{}, False{}, S.CW{t[U32.add(tp.PU(), U32.add(U32.mul(sp2, 40320), ud2))], res},
        bud, cp, ud, sp, lf, path, i, cp2, ud2, sp2, v)
    case _ 1n+fq ZR5{} _ _ _ _ S.CW{r, +res}:
      # the child's bound: its two distances' larger (words are d + 1)
      (t, +v) = r
      +h = U32.sub(U32.max(hc, v), 1)
      tp.go2(d, fq, ZDec{}, True{}, True{}, U32.is_ge(h, bud), U32.is_zero(h), S.CW{(t, 0), res},
        bud, cp, ud, sp, lf, path, i, cp2, ud2, sp2, hc)
    case _ 1n+fq ZDec{} _ _ True{} _ S.CW{r, +res}:
      +inx = U32.add(i, 1)
      tp.go2(d, fq, ZTry{}, U32.is_lt(inx, 10), S.sr.allowed(tp.mv(inx), lf), False{}, False{}, S.CW{r, S.sr.count(res)},
        bud, cp, ud, sp, lf, path, inx, 0, 0, 0, 0)
    case _ 1n+fq ZDec{} _ _ False{} True{} S.CW{r, +res}:
      tp.go2(d, fq, ZTry{}, False{}, False{}, False{}, False{}, S.CW{r, S.sr.win(res, tp.mv(i) <> path)},
        bud, cp, ud, sp, lf, path, i, 0, 0, 0, 0)
    case 0n 1n+fq ZDec{} _ _ False{} False{} S.CW{r, +res}:
      S.sr.out(S.CW{r, res})
    case 1n+dq 1n+fq ZDec{} _ _ False{} False{} S.CW{r, +res}:
      +m = tp.mv(i)
      +f = S.sr.face(m)
      tp.go2(d, fq, ZBack{}, True{}, True{}, False{}, False{},
        S.CR{tp.go2(dq, 255n, ZTry{}, True{}, S.sr.allowed(tp.mv(0), f), False{}, False{}, S.CW{r, S.sr.count(res)},
          U32.sub(bud, 1), cp2, ud2, sp2, f, m <> path, 0, 0, 0, 0, 0)},
        bud, cp, ud, sp, lf, path, i, 0, 0, 0, 0)
    case _ 1n+fq ZBack{} _ _ _ _ S.CR{r}:
      (t, +res) = r
      +inx = U32.add(i, 1)
      tp.go2(d, fq, ZTry{}, Bool.and(U32.is_lt(inx, 10), Bool.not(S.sr.found(res))), S.sr.allowed(tp.mv(inx), lf), False{}, False{}, S.CW{(t, 0), res},
        bud, cp, ud, sp, lf, path, inx, 0, 0, 0, 0)
    case _ 1n+fq _ _ _ _ _ _:
      S.sr.out(c)

# a search of depth d below (cp, ud, sp) (path: the moves so far, last first)
def tp.below2(+d: U32, t: Array<U32>, +cp: U32, +ud: U32, +sp: U32, +lf: U32, +path: List<&2, U32>) -> Array<U32> & S.Res:
  tp.go2(U32.to_nat(d), 255n, ZTry{}, True{}, S.sr.allowed(tp.mv(0), lf), False{}, False{}, S.CW{(t, 0), S.Res{None{}, 0}},
    d, cp, ud, sp, lf, path, 0, 0, 0, 0, 0)

def tp.add.res(r: Array<U32> & S.Res, +k: U32) -> Array<U32> & S.Res:
  (t, res) = r
  match res:
    case S.Res{f, n}:
      (t, S.Res{f, U32.add(n, k)})

# bounds b.. (k of them) until one has a solution: phase 2's shortest
def tp.ida2(k: Nat, r: Array<U32> & S.Res, +b: U32, +cp: U32, +ud: U32, +sp: U32, +lf: U32, +path: List<&2, U32>) -> Array<U32> & S.Res:
  match k:
    case 0n:
      r
    case 1n+q:
      (t, res) = r
      match res:
        case S.Res{Some{+xs}, n}:
          (t, S.Res{Some{xs}, n})
        case S.Res{None{}, +n}:
          tp.ida2(q, tp.add.res(tp.below2(b, t, cp, ud, sp, lf, path), n), U32.add(b, 1), cp, ud, sp, lf, path)

# Phase 1's search
# ----------------

# The best so far: a solution (its moves, in order) and its length (99 for
# none), how many ways into S were tried, and the nodes made
type Best is Data:
  Best{+sol: Maybe<&2, List<&2, U32>>, +len: U32, +tries: U32, +nodes: U32}

def tp.budget() -> U32:
  700

def tp.more(+b: Best, +l1: U32) -> Bool:
  match b:
    case Best{s, len, tries, n}:
      Bool.and(U32.is_lt(tries, tp.budget()), U32.is_gt(len, l1))

def tp.len(xs: List<&2, U32>) -> U32:
  match xs:
    case Nil{}:
      0
    case Con{x, t}:
      U32.add(tp.len(t), 1)

def tp.h2.got(r: Array<U32> & U32, +hc: U32) -> Array<U32> & U32:
  (t, +v) = r
  (t, U32.sub(U32.max(hc, v), 1))

def tp.h2.c(r: Array<U32> & U32, +i: U32) -> Array<U32> & U32:
  (t, +v) = r
  tp.h2.got(t[U32.add(tp.PU(), i)], v)

# phase 2's bound for (cp, ud, sp)
def tp.h2(t: Array<U32>, +cp: U32, +ud: U32, +sp: U32) -> Array<U32> & U32:
  tp.h2.c(t[U32.add(tp.PC(), U32.add(U32.mul(sp, 40320), cp))], U32.add(U32.mul(sp, 40320), ud))

# a phase-2 solution found: the whole, if shorter than the best
def tp.take2.go(res: S.Res, +b: Best, t: Array<U32>, +p1: List<&2, U32>, +l1: U32) -> Array<U32> & Best:
  match res b:
    case S.Res{Some{+xs}, n} Best{s, len, tries, nodes}:
      +l = U32.add(l1, tp.len(xs))
      +better = U32.is_lt(l, len)
      (t, Best{Bool.pick(Maybe<&2, List<&2, U32>>, better, Some{List.append(&2, U32, p1, xs)}, s), Bool.pick(U32, better, l, len),
        U32.add(tries, 1), U32.add(nodes, n)})
    case S.Res{None{}, n} Best{s, len, tries, nodes}:
      (t, Best{s, len, U32.add(tries, 1), U32.add(nodes, n)})

def tp.take2(r: Array<U32> & S.Res, +p1: List<&2, U32>, +l1: U32, +b: Best) -> Array<U32> & Best:
  (t, res) = r
  tp.take2.go(res, b, t, p1, l1)

# phase 2 from (cp, ud, sp), its bound h: none needed if h is 0 (phase 1
# solved it); else bounds h .. len - l1 - 1, so the whole beats the best
def tp.blen(+b: Best) -> U32:
  match b:
    case Best{s, len, tries, nodes}:
      len

def tp.leaf.k(home: Bool, t: Array<U32>, +h: U32, +k: U32, +cp: U32, +ud: U32, +sp: U32, +lf: U32) -> Array<U32> & S.Res:
  match home:
    case True{}:
      (t, S.Res{Some{Nil{}}, 0})
    case False{}:
      tp.ida2(U32.to_nat(k), (t, S.Res{None{}, 0}), h, cp, ud, sp, lf, Nil{})

def tp.leaf.top(+b: Best, +l1: U32, +h: U32) -> U32:
  match b:
    case Best{s, len, tries, nodes}:
      +top = U32.sub(U32.sub(len, l1), 1)
      Bool.pick(U32, Bool.or(U32.is_lt(len, U32.add(l1, 1)), U32.is_gt(h, top)), 0, U32.add(U32.sub(top, h), 1))

def tp.leaf.go(r: Array<U32> & U32, +cp: U32, +ud: U32, +sp: U32, +p1: List<&2, U32>, +l1: U32, +lf: U32, +b: Best) -> Array<U32> & Best:
  (t, +h) = r
  +k = tp.leaf.top(b, l1, h)
  tp.take2(tp.leaf.k(Bool.and(U32.is_zero(h), U32.is_lt(l1, tp.blen(b))), t, h, k, cp, ud, sp, lf), p1, l1, b)


# A way into S: p1, its moves (in order), l1 of them, from the cube c0; c1
# the cube after them. Phase 2 from there.
def tp.leaf(t: Array<U32>, +c1: C.Cube, +p1: List<&2, U32>, +l1: U32, +lf: U32, +b: Best) -> Array<U32> & Best:
  +ep = tp.ep(c1)
  +cp = tp.cp.of(c1)
  +ud = tp.ud.of(ep)
  +sp = tp.sp.of(ep)
  tp.leaf.go(tp.h2(t, cp, ud, sp), cp, ud, sp, p1, l1, lf, b)

# What a step is about to do: a move tried, its child's coordinates read one
# word at a time (the U-D axis's flip, slice, twist, then its class, twist
# turned, distance), then cut, a way into S, or below
type Y is Data:
  YTry{}
  YR1{}
  YR2{}
  YR3{}
  YR4{}
  YR5{}
  YR6{}
  YDec{}
  YLeaf{}
  YBack{}

# The array and the best so far (the word last read beside them), or a
# child's answer
type Q is Type:
  QW{r: Array<U32> & U32, +b: Best}
  QR{r: Array<U32> & Best}

def tp.out(q: Q) -> Array<U32> & Best:
  match q:
    case QW{r, b}:
      (t, v) = r
      (t, b)
    case QR{r}:
      r

def tp.bump(+b: Best) -> Best:
  match b:
    case Best{s, len, tries, nodes}:
      Best{s, len, tries, U32.add(nodes, 1)}

# Phase 1 below a node (twist tw, raw r: Sym.bend's slice * 2048 + flip),
# d moves left (bud), l1 the whole way's length: a child is cut unless its
# exact distance to S is within what is left; with one left, a child in S
# is a way into S, and phase 2 goes on from it. The cube c0: where the
# search began (its moves path, last first).
#   f2, s2, w2: the child's flip, slice, twist; cl: its class's word
def tp.go1(
  +d: Nat, fuel: Nat, op: Y, more: Bool, ok: Bool, q: Q,
  +bud: U32, +l1: U32, +tw: U32, +rw: U32, +lf: U32, +path: List<&2, U32>, +m: U32, +c0: C.Cube,
  +f2: U32, +s2: U32, +w2: U32, +cl: U32, +tc: U32
) -> Array<U32> & Best:
  match d fuel op more ok q:
    case _ 0n _ _ _ _:
      tp.out(q)
    case _ 1n+fq YTry{} False{} _ _:
      tp.out(q)
    case _ 1n+fq YTry{} True{} False{} QW{r, +b}:
      +mn = U32.add(m, 1)
      tp.go1(d, fq, YTry{}, Bool.and(U32.is_lt(mn, 18), tp.more(b, l1)), S.sr.allowed(mn, lf), QW{r, b},
        bud, l1, tw, rw, lf, path, mn, c0, 0, 0, 0, 0, 0)
    case _ 1n+fq YTry{} True{} True{} QW{r, +b}:
      (t, z) = r
      tp.go1(d, fq, YR1{}, True{}, True{}, QW{t[U32.add(T.kc.FM(), U32.add(U32.mul(U32.and(rw, 2047), 18), m))], b},
        bud, l1, tw, rw, lf, path, m, c0, 0, 0, 0, 0, 0)
    case _ 1n+fq YR1{} _ _ QW{r, +b}:
      (t, +v) = r
      tp.go1(d, fq, YR2{}, True{}, True{}, QW{t[U32.add(T.kc.SM(), U32.add(U32.mul(U32.shrn(rw, 11n), 18), m))], b},
        bud, l1, tw, rw, lf, path, m, c0, v, 0, 0, 0, 0)
    case _ 1n+fq YR2{} _ _ QW{r, +b}:
      (t, +v) = r
      tp.go1(d, fq, YR3{}, True{}, True{}, QW{t[U32.add(K.co.T.tw(), U32.add(U32.mul(tw, 18), m))], b},
        bud, l1, tw, rw, lf, path, m, c0, f2, v, 0, 0, 0)
    case _ 1n+fq YR3{} _ _ QW{r, +b}:
      (t, +v) = r
      tp.go1(d, fq, YR4{}, True{}, True{}, QW{t[U32.add(T.kc.CL(), U32.add(U32.mul(s2, 2048), f2))], b},
        bud, l1, tw, rw, lf, path, m, c0, f2, s2, v, 0, 0)
    case _ 1n+fq YR4{} _ _ QW{r, +b}:
      (t, +v) = r
      tp.go1(d, fq, YR5{}, True{}, True{}, QW{t[U32.add(T.kc.TC(), U32.add(U32.mul(w2, 8), U32.and(v, 7)))], b},
        bud, l1, tw, rw, lf, path, m, c0, f2, s2, w2, v, 0)
    case _ 1n+fq YR5{} _ _ QW{r, +b}:
      (t, +v) = r
      tp.go1(d, fq, YR6{}, True{}, True{}, QW{t[T.kc.word(U32.shrn(cl, 4n), v)], b},
        bud, l1, tw, rw, lf, path, m, c0, f2, s2, w2, cl, v)
    case _ 1n+fq YR6{} _ _ QW{r, +b}:
      # the child's exact distance to S: within what is left after this move?
      (t, +v) = r
      +h = T.kc.nib(v, U32.and(tc, 7))
      tp.go1(d, fq, Bool.pick(Y, U32.is_eq(bud, 1), YLeaf{}, YDec{}), True{}, U32.is_lt(h, bud), QW{(t, 0), tp.bump(b)},
        bud, l1, tw, rw, lf, path, m, c0, f2, s2, w2, cl, tc)
    case _ 1n+fq YLeaf{} _ False{} QW{r, +b}:
      # cut: the next move
      +mn = U32.add(m, 1)
      tp.go1(d, fq, YTry{}, Bool.and(U32.is_lt(mn, 18), tp.more(b, l1)), S.sr.allowed(mn, lf), QW{r, b},
        bud, l1, tw, rw, lf, path, mn, c0, 0, 0, 0, 0, 0)
    case _ 1n+fq YLeaf{} _ True{} QW{r, +b}:
      # the last move: the child is in S, a way in; phase 2 from it
      (t, z) = r
      +p1 = List.reverse(&2, U32, m <> path)
      tp.go1(d, fq, YBack{}, True{}, True{}, QR{tp.leaf(t, C.cube.apply(p1, c0), p1, l1, S.sr.face(m), b)},
        bud, l1, tw, rw, lf, path, m, c0, 0, 0, 0, 0, 0)
    case _ 1n+fq YDec{} _ False{} QW{r, +b}:
      # cut: the next move
      +mn = U32.add(m, 1)
      tp.go1(d, fq, YTry{}, Bool.and(U32.is_lt(mn, 18), tp.more(b, l1)), S.sr.allowed(mn, lf), QW{r, b},
        bud, l1, tw, rw, lf, path, mn, c0, 0, 0, 0, 0, 0)
    case 0n 1n+fq YDec{} _ True{} QW{r, +b}:
      tp.out(QW{r, b})
    case 1n+dq 1n+fq YDec{} _ True{} QW{r, +b}:
      # within reach: phase 1 below the child
      (t, z) = r
      +f = S.sr.face(m)
      tp.go1(d, fq, YBack{}, True{}, True{},
        QR{tp.go1(dq, 255n, YTry{}, tp.more(b, l1), S.sr.allowed(0, f), QW{(t, 0), b},
          U32.sub(bud, 1), l1, w2, U32.add(U32.mul(s2, 2048), f2), f, m <> path, 0, c0, 0, 0, 0, 0, 0)},
        bud, l1, tw, rw, lf, path, m, c0, 0, 0, 0, 0, 0)
    case _ 1n+fq YBack{} _ _ QR{r}:
      (t, +b) = r
      +mn = U32.add(m, 1)
      tp.go1(d, fq, YTry{}, Bool.and(U32.is_lt(mn, 18), tp.more(b, l1)), S.sr.allowed(mn, lf), QW{(t, 0), b},
        bud, l1, tw, rw, lf, path, mn, c0, 0, 0, 0, 0, 0)
    case _ 1n+fq _ _ _ _:
      tp.out(q)

# every way into S of l1 moves from the cube c0 (tw, rw its twist and raw)
def tp.below1(+l1: U32, t: Array<U32>, +tw: U32, +rw: U32, +c0: C.Cube, +b: Best) -> Array<U32> & Best:
  tp.go1(U32.to_nat(l1), 255n, YTry{}, tp.more(b, l1), S.sr.allowed(0, 6), QW{(t, 0), b},
    l1, l1, tw, rw, 6, Nil{}, 0, c0, 0, 0, 0, 0, 0)

# phase 1's ways in of l1 moves, if they can still do better
def tp.step1(go: Bool, t: Array<U32>, +b: Best, +l1: U32, +tw: U32, +rw: U32, +c0: C.Cube) -> Array<U32> & Best:
  match go:
    case False{}:
      (t, b)
    case True{}:
      tp.below1(l1, t, tw, rw, c0, b)

# phase 1's lengths l1.. (k of them)
def tp.ida1(k: Nat, r: Array<U32> & Best, +l1: U32, +tw: U32, +rw: U32, +c0: C.Cube) -> Array<U32> & Best:
  match k:
    case 0n:
      r
    case 1n+q:
      (t, +b) = r
      tp.ida1(q, tp.step1(tp.more(b, l1), t, b, l1, tw, rw, c0), U32.add(l1, 1), tw, rw, c0)

# The solve
# ---------

# the start: already in S (phase 2 at once), and phase 1's lengths from its
# distance on
def tp.start.go(home: Bool, t: Array<U32>, +h: U32, +tw: U32, +rw: U32, +c0: C.Cube) -> Array<U32> & Best:
  match home:
    case True{}:
      tp.ida1(8n, tp.leaf(t, c0, Nil{}, 0, 6, Best{None{}, 99, 0, 0}), 1, tw, rw, c0)
    case False{}:
      tp.ida1(8n, (t, Best{None{}, 99, 0, 0}), h, tw, rw, c0)

def tp.start(r: Array<U32> & U32, +tw: U32, +rw: U32, +c0: C.Cube) -> Array<U32> & Best:
  (t, +h) = r
  tp.start.go(U32.is_zero(h), t, h, tw, rw, c0)

# a cube's exact distance to S, from its raw's class, then its twist turned
def tp.dist3(r: Array<U32> & U32, +tc: U32) -> Array<U32> & U32:
  (t, +w) = r
  (t, T.kc.nib(w, U32.and(tc, 7)))

def tp.dist2(r: Array<U32> & U32, +cl: U32) -> Array<U32> & U32:
  (t, +tc) = r
  tp.dist3(t[T.kc.word(U32.shrn(cl, 4n), tc)], tc)

def tp.dist(r: Array<U32> & U32, +tw: U32) -> Array<U32> & U32:
  (t, +cl) = r
  tp.dist2(t[U32.add(T.kc.TC(), U32.add(U32.mul(tw, 8), U32.and(cl, 7)))], cl)

# A short solution of the cube c0, twist tw and raw rw on the U-D axis
# (Opt.bend's node's t0 and r0)
def tp.solve(t: Array<U32>, +tw: U32, +rw: U32, +c0: C.Cube) -> Array<U32> & Best:
  tp.start(tp.dist(t[U32.add(T.kc.CL(), rw)], tw), tw, rw, c0)
