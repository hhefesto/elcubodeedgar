import Base
import ./Cube.bend as C
import ./Coord.bend as K
import ./Search.bend as S
import ./Sym.bend as Y

# A short solution at once, with small tables: Kociemba's two-phase
# algorithm (1992) as TwoPhase.bend's, for a device (a phone, a browser)
# that cannot hold Kc.bend's 3.6 GB table. Phase 1 takes the cube into S
# (edges unflipped, corners untwisted, the four U-D slice edges in the
# slice), its bound the larger of two exact distances of parts: of the
# edges' flips with the slice edges' places (2048 * 495), and of the
# corners' twists with them (2187 * 495). Phase 2 is TwoPhase.bend's: U, D
# and the half turns, bounded by its two tables. The answer is a solution
# of the cube (checked again with Cube.bend before it is shown), not always
# the shortest.
#
# The tables, in the device's one array (Dev.bend), above Coord.bend's:
#   lt.FM   a flip's moves, f * 18 + m (Kc.bend's offset)
#   lt.U5M  the slice edges' places (a 4 of 12, ranked 0..494) moves
#   lt.P1F  at u * 2048 + f: the distance of (places u, flip f) to S's, plus 1
#   lt.P1T  at u * 2187 + w: the same for (places u, twist w)
#   lt.UDM, lt.SPM, lt.PC, lt.PU: phase 2's, as TwoPhase.bend's
#
# Every def is prefixed `lt.`.

def lt.FM() -> U32:
  35000000

def lt.U5M() -> U32:
  35040000

def lt.P1F() -> U32:
  35050000

def lt.P1T() -> U32:
  36070000

def lt.UDM() -> U32:
  37160000

def lt.SPM() -> U32:
  37570000

def lt.PC() -> U32:
  37580000

def lt.PU() -> U32:
  38550000

# the array's length: past PU's last word
def lt.end() -> U32:
  39517680

# entries in each of PC and PU: 24 * 40320
def lt.n2() -> U32:
  967680

# phase 2's moves, i = 0..9: U U2 U' D D2 D' R2 L2 F2 B2
def lt.mv(+i: U32) -> U32:
  Bool.pick(U32, U32.is_lt(i, 3), i,
    Bool.pick(U32, U32.is_lt(i, 6), U32.add(i, 6),
      Bool.pick(U32, U32.is_eq(i, 6), 4,
        Bool.pick(U32, U32.is_eq(i, 7), 13, Bool.pick(U32, U32.is_eq(i, 8), 7, 16)))))

# Phase 2's coordinates
# ---------------------

# xs, each less 8
def lt.sub8(xs: List<&2, U32>) -> List<&2, U32>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+x, t}:
      U32.sub(x, 8) <> lt.sub8(t)

def lt.add8(xs: List<&2, U32>) -> List<&2, U32>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+x, t}:
      U32.add(x, 8) <> lt.add8(t)

# the U and D edges' places: which of UR..DB is at each of places 0..7
def lt.ud.of(+ep: List<&2, U32>) -> U32:
  K.co.rank(List.take(&2, U32, ep, 8n))

# the slice edges' order: which of FR..BR is at each of places 8..11
def lt.sp.of(+ep: List<&2, U32>) -> U32:
  K.co.rank(lt.sub8(List.drop(&2, U32, ep, 8n)))

def lt.cp.of(+c: C.Cube) -> U32:
  match c:
    case C.Cube{cp, co, ep, eo}:
      K.co.rank(cp)

def lt.ep(+c: C.Cube) -> List<&2, U32>:
  match c:
    case C.Cube{cp, co, ep, eo}:
      ep

# a cube's ep with the U and D edges at ud, the slice's home; and the other way
def lt.ud.ep(+ud: U32) -> List<&2, U32>:
  List.append(&2, U32, K.co.unrank(8n, ud, K.co.range(8n)), [8, 9, 10, 11])

def lt.sp.ep(+sp: U32) -> List<&2, U32>:
  List.append(&2, U32, K.co.range(8n), lt.add8(K.co.unrank(4n, sp, K.co.range(4n))))

# phase 2's moves' ep, once
def lt.meps.go(n: Nat, +i: U32) -> List<&2, List<&2, U32>>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      lt.ep(C.cube.move(lt.mv(i))) <> lt.meps.go(p, U32.add(i, 1))

def lt.meps() -> List<&2, List<&2, U32>>:
  lt.meps.go(10n, 0)

# The move tables
# ---------------

def lt.udm.row(ms: List<&2, List<&2, U32>>, +ep: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+mep, t}:
      lt.ud.of(C.cube.mul.p(ep, mep)) <> lt.udm.row(t, ep)

def lt.spm.row(ms: List<&2, List<&2, U32>>, +ep: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+mep, t}:
      lt.sp.of(C.cube.mul.p(ep, mep)) <> lt.spm.row(t, ep)

def lt.fill.udm(n: Nat, t: Array<U32>, +ud: U32, +ms: List<&2, List<&2, U32>>) -> Array<U32>:
  match n:
    case 0n:
      t
    case 1n+p:
      +row = lt.udm.row(ms, lt.ud.ep(ud))
      lt.fill.udm(p, K.co.write(row, t, U32.add(lt.UDM(), U32.mul(ud, 10))), U32.add(ud, 1), ms)

def lt.fill.spm(n: Nat, t: Array<U32>, +sp: U32, +ms: List<&2, List<&2, U32>>) -> Array<U32>:
  match n:
    case 0n:
      t
    case 1n+p:
      +row = lt.spm.row(ms, lt.sp.ep(sp))
      lt.fill.spm(p, K.co.write(row, t, U32.add(lt.SPM(), U32.mul(sp, 10))), U32.add(sp, 1), ms)

# The distance tables, breadth first
# ----------------------------------

# which: the corners' places (their moves Coord.bend's, all 18), or the U and
# D edges' (lt.UDM)
type P2 is Data:
  PC{}
  PU{}

def lt.p2.at(+k: P2) -> U32:
  match k:
    case PC{}:
      lt.PC()
    case PU{}:
      lt.PU()

# where x's move i is
def lt.p2.xm(+k: P2, +x: U32, +i: U32) -> U32:
  match k:
    case PC{}:
      U32.add(K.co.T.cp(), U32.add(U32.mul(x, 18), lt.mv(i)))
    case PU{}:
      U32.add(lt.UDM(), U32.add(U32.mul(x, 10), i))

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
def lt.bfs(
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
      lt.bfs(nq, 63n, BE{}, True{}, t[U32.add(lt.p2.at(k), en)], k, d, en, 0, 0, 0, 0, 0, cnt)
    case 1n+nq 1n+fq BE{} _:
      (t, +v) = r
      lt.bfs(n, fq, BM{}, U32.is_eq(v, U32.add(d, 1)), (t, 0), k, d, e, U32.mod(e, 40320), U32.div(e, 40320), 0, 0, 0, cnt)
    case 1n+nq 1n+fq BM{} False{}:
      # the next entry
      (t, z) = r
      +en = U32.add(e, 1)
      lt.bfs(nq, 63n, BE{}, True{}, t[U32.add(lt.p2.at(k), en)], k, d, en, 0, 0, 0, 0, 0, cnt)
    case 1n+nq 1n+fq BM{} True{}:
      (t, z) = r
      lt.bfs(n, fq, BX{}, True{}, t[lt.p2.xm(k, x, i)], k, d, e, x, sp, i, 0, 0, cnt)
    case 1n+nq 1n+fq BX{} _:
      (t, +v) = r
      lt.bfs(n, fq, BY{}, True{}, t[U32.add(lt.SPM(), U32.add(U32.mul(sp, 10), i))], k, d, e, x, sp, i, v, 0, cnt)
    case 1n+nq 1n+fq BY{} _:
      (t, +v) = r
      +cc = U32.add(U32.mul(v, 40320), x2)
      lt.bfs(n, fq, BC{}, True{}, t[U32.add(lt.p2.at(k), cc)], k, d, e, x, sp, i, x2, cc, cnt)
    case 1n+nq 1n+fq BC{} _:
      (t, +v) = r
      +fresh = U32.is_zero(v)
      t2 = Array.set(U32, t, U32.add(lt.p2.at(k), c), Bool.pick(U32, fresh, U32.add(d, 2), v))
      +inx = U32.add(i, 1)
      lt.bfs(n, fq, BM{}, U32.is_lt(inx, 10), (t2, 0), k, d, e, x, sp, inx, 0, 0, U32.add(cnt, Bool.to_u32(fresh)))

def lt.level(t: Array<U32>, +k: P2, +d: U32) -> Array<U32> & U32:
  lt.bfs(U32.to_nat(lt.n2()), 63n, BE{}, True{}, t[lt.p2.at(k)], k, d, 0, 0, 0, 0, 0, 0, 0)

def lt.levels(n: Nat, r: Array<U32> & U32, +k: P2, +d: U32) -> Array<U32>:
  match n:
    case 0n:
      (t, v) = r
      t
    case 1n+q:
      (t, +c) = r
      lt.levels(q, lt.level(t, k, d), k, U32.add(d, 1))

# Phase 2's tables, in t beside Coord.bend's (whose corners' moves they use):
# the moves, then each distance table from solved (its entry 0, word 1)
def lt.tables(t: Array<U32>) -> Array<U32>:
  +ms = lt.meps()
  t1 = lt.fill.spm(24n, lt.fill.udm(40320n, t, 0, ms), 0, ms)
  t2 = Array.set(U32, Array.set(U32, t1, lt.PC(), 1), lt.PU(), 1)
  lt.levels(20n, (lt.levels(20n, (t2, 0), PC{}, 0), 0), PU{}, 0)

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
# U32), its moves phase 2's (move i is lt.mv(i)), Search.bend's rules kept
# (lf: the last move's face, also phase 1's last). hc: the child's corner
# entry, until its edges' is read.
def lt.go2(
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
      lt.go2(d, fq, ZTry{}, Bool.and(U32.is_lt(inx, 10), Bool.not(S.sr.found(res))), S.sr.allowed(lt.mv(inx), lf), False{}, False{}, S.CW{r, res},
        bud, cp, ud, sp, lf, path, inx, 0, 0, 0, 0)
    case _ 1n+fq ZTry{} True{} True{} _ _ S.CW{r, +res}:
      (t, z) = r
      lt.go2(d, fq, ZR1{}, True{}, True{}, False{}, False{}, S.CW{t[U32.add(K.co.T.cp(), U32.add(U32.mul(cp, 18), lt.mv(i)))], res},
        bud, cp, ud, sp, lf, path, i, 0, 0, 0, 0)
    case _ 1n+fq ZR1{} _ _ _ _ S.CW{r, +res}:
      (t, +v) = r
      lt.go2(d, fq, ZR2{}, True{}, True{}, False{}, False{}, S.CW{t[U32.add(lt.UDM(), U32.add(U32.mul(ud, 10), i))], res},
        bud, cp, ud, sp, lf, path, i, v, 0, 0, 0)
    case _ 1n+fq ZR2{} _ _ _ _ S.CW{r, +res}:
      (t, +v) = r
      lt.go2(d, fq, ZR3{}, True{}, True{}, False{}, False{}, S.CW{t[U32.add(lt.SPM(), U32.add(U32.mul(sp, 10), i))], res},
        bud, cp, ud, sp, lf, path, i, cp2, v, 0, 0)
    case _ 1n+fq ZR3{} _ _ _ _ S.CW{r, +res}:
      (t, +v) = r
      lt.go2(d, fq, ZR4{}, True{}, True{}, False{}, False{}, S.CW{t[U32.add(lt.PC(), U32.add(U32.mul(v, 40320), cp2))], res},
        bud, cp, ud, sp, lf, path, i, cp2, ud2, v, 0)
    case _ 1n+fq ZR4{} _ _ _ _ S.CW{r, +res}:
      (t, +v) = r
      lt.go2(d, fq, ZR5{}, True{}, True{}, False{}, False{}, S.CW{t[U32.add(lt.PU(), U32.add(U32.mul(sp2, 40320), ud2))], res},
        bud, cp, ud, sp, lf, path, i, cp2, ud2, sp2, v)
    case _ 1n+fq ZR5{} _ _ _ _ S.CW{r, +res}:
      # the child's bound: its two distances' larger (words are d + 1)
      (t, +v) = r
      +h = U32.sub(U32.max(hc, v), 1)
      lt.go2(d, fq, ZDec{}, True{}, True{}, U32.is_ge(h, bud), U32.is_zero(h), S.CW{(t, 0), res},
        bud, cp, ud, sp, lf, path, i, cp2, ud2, sp2, hc)
    case _ 1n+fq ZDec{} _ _ True{} _ S.CW{r, +res}:
      +inx = U32.add(i, 1)
      lt.go2(d, fq, ZTry{}, U32.is_lt(inx, 10), S.sr.allowed(lt.mv(inx), lf), False{}, False{}, S.CW{r, S.sr.count(res)},
        bud, cp, ud, sp, lf, path, inx, 0, 0, 0, 0)
    case _ 1n+fq ZDec{} _ _ False{} True{} S.CW{r, +res}:
      lt.go2(d, fq, ZTry{}, False{}, False{}, False{}, False{}, S.CW{r, S.sr.win(res, lt.mv(i) <> path)},
        bud, cp, ud, sp, lf, path, i, 0, 0, 0, 0)
    case 0n 1n+fq ZDec{} _ _ False{} False{} S.CW{r, +res}:
      S.sr.out(S.CW{r, res})
    case 1n+dq 1n+fq ZDec{} _ _ False{} False{} S.CW{r, +res}:
      +m = lt.mv(i)
      +f = S.sr.face(m)
      lt.go2(d, fq, ZBack{}, True{}, True{}, False{}, False{},
        S.CR{lt.go2(dq, 255n, ZTry{}, True{}, S.sr.allowed(lt.mv(0), f), False{}, False{}, S.CW{r, S.sr.count(res)},
          U32.sub(bud, 1), cp2, ud2, sp2, f, m <> path, 0, 0, 0, 0, 0)},
        bud, cp, ud, sp, lf, path, i, 0, 0, 0, 0)
    case _ 1n+fq ZBack{} _ _ _ _ S.CR{r}:
      (t, +res) = r
      +inx = U32.add(i, 1)
      lt.go2(d, fq, ZTry{}, Bool.and(U32.is_lt(inx, 10), Bool.not(S.sr.found(res))), S.sr.allowed(lt.mv(inx), lf), False{}, False{}, S.CW{(t, 0), res},
        bud, cp, ud, sp, lf, path, inx, 0, 0, 0, 0)
    case _ 1n+fq _ _ _ _ _ _:
      S.sr.out(c)

# a search of depth d below (cp, ud, sp) (path: the moves so far, last first)
def lt.below2(+d: U32, t: Array<U32>, +cp: U32, +ud: U32, +sp: U32, +lf: U32, +path: List<&2, U32>) -> Array<U32> & S.Res:
  lt.go2(U32.to_nat(d), 255n, ZTry{}, True{}, S.sr.allowed(lt.mv(0), lf), False{}, False{}, S.CW{(t, 0), S.Res{None{}, 0}},
    d, cp, ud, sp, lf, path, 0, 0, 0, 0, 0)

def lt.add.res(r: Array<U32> & S.Res, +k: U32) -> Array<U32> & S.Res:
  (t, res) = r
  match res:
    case S.Res{f, n}:
      (t, S.Res{f, U32.add(n, k)})

# bounds b.. (k of them) until one has a solution: phase 2's shortest
def lt.ida2(k: Nat, r: Array<U32> & S.Res, +b: U32, +cp: U32, +ud: U32, +sp: U32, +lf: U32, +path: List<&2, U32>) -> Array<U32> & S.Res:
  match k:
    case 0n:
      r
    case 1n+q:
      (t, res) = r
      match res:
        case S.Res{Some{+xs}, n}:
          (t, S.Res{Some{xs}, n})
        case S.Res{None{}, +n}:
          lt.ida2(q, lt.add.res(lt.below2(b, t, cp, ud, sp, lf, path), n), U32.add(b, 1), cp, ud, sp, lf, path)

# Phase 1's search
# ----------------

# The best so far: a solution (its moves, in order) and its length (99 for
# none), how many ways into S were tried, and the nodes made
type Best is Data:
  Best{+sol: Maybe<&2, List<&2, U32>>, +len: U32, +tries: U32, +nodes: U32}

def lt.budget() -> U32:
  700

def lt.more(+b: Best, +l1: U32) -> Bool:
  match b:
    case Best{s, len, tries, n}:
      Bool.and(U32.is_lt(tries, lt.budget()), U32.is_gt(len, l1))

def lt.len(xs: List<&2, U32>) -> U32:
  match xs:
    case Nil{}:
      0
    case Con{x, t}:
      U32.add(lt.len(t), 1)

def lt.h2.got(r: Array<U32> & U32, +hc: U32) -> Array<U32> & U32:
  (t, +v) = r
  (t, U32.sub(U32.max(hc, v), 1))

def lt.h2.c(r: Array<U32> & U32, +i: U32) -> Array<U32> & U32:
  (t, +v) = r
  lt.h2.got(t[U32.add(lt.PU(), i)], v)

# phase 2's bound for (cp, ud, sp)
def lt.h2(t: Array<U32>, +cp: U32, +ud: U32, +sp: U32) -> Array<U32> & U32:
  lt.h2.c(t[U32.add(lt.PC(), U32.add(U32.mul(sp, 40320), cp))], U32.add(U32.mul(sp, 40320), ud))

# a phase-2 solution found: the whole, if shorter than the best
def lt.take2.go(res: S.Res, +b: Best, t: Array<U32>, +p1: List<&2, U32>, +l1: U32) -> Array<U32> & Best:
  match res b:
    case S.Res{Some{+xs}, n} Best{s, len, tries, nodes}:
      +l = U32.add(l1, lt.len(xs))
      +better = U32.is_lt(l, len)
      (t, Best{Bool.pick(Maybe<&2, List<&2, U32>>, better, Some{List.append(&2, U32, p1, xs)}, s), Bool.pick(U32, better, l, len),
        U32.add(tries, 1), U32.add(nodes, n)})
    case S.Res{None{}, n} Best{s, len, tries, nodes}:
      (t, Best{s, len, U32.add(tries, 1), U32.add(nodes, n)})

def lt.take2(r: Array<U32> & S.Res, +p1: List<&2, U32>, +l1: U32, +b: Best) -> Array<U32> & Best:
  (t, res) = r
  lt.take2.go(res, b, t, p1, l1)

# phase 2 from (cp, ud, sp), its bound h: none needed if h is 0 (phase 1
# solved it); else bounds h .. len - l1 - 1, so the whole beats the best
def lt.blen(+b: Best) -> U32:
  match b:
    case Best{s, len, tries, nodes}:
      len

def lt.leaf.k(home: Bool, t: Array<U32>, +h: U32, +k: U32, +cp: U32, +ud: U32, +sp: U32, +lf: U32) -> Array<U32> & S.Res:
  match home:
    case True{}:
      (t, S.Res{Some{Nil{}}, 0})
    case False{}:
      lt.ida2(U32.to_nat(k), (t, S.Res{None{}, 0}), h, cp, ud, sp, lf, Nil{})

def lt.leaf.top(+b: Best, +l1: U32, +h: U32) -> U32:
  match b:
    case Best{s, len, tries, nodes}:
      +top = U32.sub(U32.sub(len, l1), 1)
      Bool.pick(U32, Bool.or(U32.is_lt(len, U32.add(l1, 1)), U32.is_gt(h, top)), 0, U32.add(U32.sub(top, h), 1))

def lt.leaf.go(r: Array<U32> & U32, +cp: U32, +ud: U32, +sp: U32, +p1: List<&2, U32>, +l1: U32, +lf: U32, +b: Best) -> Array<U32> & Best:
  (t, +h) = r
  +k = lt.leaf.top(b, l1, h)
  lt.take2(lt.leaf.k(Bool.and(U32.is_zero(h), U32.is_lt(l1, lt.blen(b))), t, h, k, cp, ud, sp, lf), p1, l1, b)


# A way into S: p1, its moves (in order), l1 of them, from the cube c0; c1
# the cube after them. Phase 2 from there.
def lt.leaf(t: Array<U32>, +c1: C.Cube, +p1: List<&2, U32>, +l1: U32, +lf: U32, +b: Best) -> Array<U32> & Best:
  +ep = lt.ep(c1)
  +cp = lt.cp.of(c1)
  +ud = lt.ud.of(ep)
  +sp = lt.sp.of(ep)
  lt.leaf.go(lt.h2(t, cp, ud, sp), cp, ud, sp, p1, l1, lf, b)

# What a step is about to do: a move tried, its child's coordinates read one
# word at a time (its flip, slice places, twist, then its two distances), then
# cut, a way into S, or below
type Y is Data:
  YTry{}
  YR1{}
  YR2{}
  YR3{}
  YR4{}
  YR5{}
  YDec{}
  YLeaf{}
  YBack{}

# The array and the best so far (the word last read beside them), or a
# child's answer
type Q is Type:
  QW{r: Array<U32> & U32, +b: Best}
  QR{r: Array<U32> & Best}

def lt.out(q: Q) -> Array<U32> & Best:
  match q:
    case QW{r, b}:
      (t, v) = r
      (t, b)
    case QR{r}:
      r

def lt.bump(+b: Best) -> Best:
  match b:
    case Best{s, len, tries, nodes}:
      Best{s, len, tries, U32.add(nodes, 1)}

# Phase 1 below a node (twist tw, raw r: its slice places' rank * 2048 + flip),
# d moves left (bud), l1 the whole way's length: a child is cut unless its
# bound on its distance to S is within what is left; with one left, a child in S
# is a way into S, and phase 2 goes on from it. The cube c0: where the
# search began (its moves path, last first).
#   f2, s2, w2: the child's flip, slice places, twist; cl: its first table's word
def lt.go1(
  +d: Nat, fuel: Nat, op: Y, more: Bool, ok: Bool, q: Q,
  +bud: U32, +l1: U32, +tw: U32, +rw: U32, +lf: U32, +path: List<&2, U32>, +m: U32, +c0: C.Cube,
  +f2: U32, +s2: U32, +w2: U32, +cl: U32, +tc: U32
) -> Array<U32> & Best:
  match d fuel op more ok q:
    case _ 0n _ _ _ _:
      lt.out(q)
    case _ 1n+fq YTry{} False{} _ _:
      lt.out(q)
    case _ 1n+fq YTry{} True{} False{} QW{r, +b}:
      +mn = U32.add(m, 1)
      lt.go1(d, fq, YTry{}, Bool.and(U32.is_lt(mn, 18), lt.more(b, l1)), S.sr.allowed(mn, lf), QW{r, b},
        bud, l1, tw, rw, lf, path, mn, c0, 0, 0, 0, 0, 0)
    case _ 1n+fq YTry{} True{} True{} QW{r, +b}:
      (t, z) = r
      lt.go1(d, fq, YR1{}, True{}, True{}, QW{t[U32.add(lt.FM(), U32.add(U32.mul(U32.and(rw, 2047), 18), m))], b},
        bud, l1, tw, rw, lf, path, m, c0, 0, 0, 0, 0, 0)
    case _ 1n+fq YR1{} _ _ QW{r, +b}:
      (t, +v) = r
      lt.go1(d, fq, YR2{}, True{}, True{}, QW{t[U32.add(lt.U5M(), U32.add(U32.mul(U32.shrn(rw, 11n), 18), m))], b},
        bud, l1, tw, rw, lf, path, m, c0, v, 0, 0, 0, 0)
    case _ 1n+fq YR2{} _ _ QW{r, +b}:
      (t, +v) = r
      lt.go1(d, fq, YR3{}, True{}, True{}, QW{t[U32.add(K.co.T.tw(), U32.add(U32.mul(tw, 18), m))], b},
        bud, l1, tw, rw, lf, path, m, c0, f2, v, 0, 0, 0)
    case _ 1n+fq YR3{} _ _ QW{r, +b}:
      (t, +v) = r
      lt.go1(d, fq, YR4{}, True{}, True{}, QW{t[U32.add(lt.P1F(), U32.add(U32.mul(s2, 2048), f2))], b},
        bud, l1, tw, rw, lf, path, m, c0, f2, s2, v, 0, 0)
    case _ 1n+fq YR4{} _ _ QW{r, +b}:
      (t, +v) = r
      lt.go1(d, fq, YR5{}, True{}, True{}, QW{t[U32.add(lt.P1T(), U32.add(U32.mul(s2, 2187), w2))], b},
        bud, l1, tw, rw, lf, path, m, c0, f2, s2, w2, v, 0)
    case _ 1n+fq YR5{} _ _ QW{r, +b}:
      # the child's bound on its distance to S (the larger of its two tables',
      # each a distance plus 1): within what is left after this move?
      (t, +v) = r
      +h = U32.sub(U32.max(cl, v), 1)
      lt.go1(d, fq, Bool.pick(Y, U32.is_eq(bud, 1), YLeaf{}, YDec{}), True{}, U32.is_lt(h, bud), QW{(t, 0), lt.bump(b)},
        bud, l1, tw, rw, lf, path, m, c0, f2, s2, w2, cl, tc)
    case _ 1n+fq YLeaf{} _ False{} QW{r, +b}:
      # cut: the next move
      +mn = U32.add(m, 1)
      lt.go1(d, fq, YTry{}, Bool.and(U32.is_lt(mn, 18), lt.more(b, l1)), S.sr.allowed(mn, lf), QW{r, b},
        bud, l1, tw, rw, lf, path, mn, c0, 0, 0, 0, 0, 0)
    case _ 1n+fq YLeaf{} _ True{} QW{r, +b}:
      # the last move: the child is in S, a way in; phase 2 from it
      (t, z) = r
      +p1 = List.reverse(&2, U32, m <> path)
      lt.go1(d, fq, YBack{}, True{}, True{}, QR{lt.leaf(t, C.cube.apply(p1, c0), p1, l1, S.sr.face(m), b)},
        bud, l1, tw, rw, lf, path, m, c0, 0, 0, 0, 0, 0)
    case _ 1n+fq YDec{} _ False{} QW{r, +b}:
      # cut: the next move
      +mn = U32.add(m, 1)
      lt.go1(d, fq, YTry{}, Bool.and(U32.is_lt(mn, 18), lt.more(b, l1)), S.sr.allowed(mn, lf), QW{r, b},
        bud, l1, tw, rw, lf, path, mn, c0, 0, 0, 0, 0, 0)
    case 0n 1n+fq YDec{} _ True{} QW{r, +b}:
      lt.out(QW{r, b})
    case 1n+dq 1n+fq YDec{} _ True{} QW{r, +b}:
      # within reach: phase 1 below the child
      (t, z) = r
      +f = S.sr.face(m)
      lt.go1(d, fq, YBack{}, True{}, True{},
        QR{lt.go1(dq, 255n, YTry{}, lt.more(b, l1), S.sr.allowed(0, f), QW{(t, 0), b},
          U32.sub(bud, 1), l1, w2, U32.add(U32.mul(s2, 2048), f2), f, m <> path, 0, c0, 0, 0, 0, 0, 0)},
        bud, l1, tw, rw, lf, path, m, c0, 0, 0, 0, 0, 0)
    case _ 1n+fq YBack{} _ _ QR{r}:
      (t, +b) = r
      +mn = U32.add(m, 1)
      lt.go1(d, fq, YTry{}, Bool.and(U32.is_lt(mn, 18), lt.more(b, l1)), S.sr.allowed(mn, lf), QW{(t, 0), b},
        bud, l1, tw, rw, lf, path, mn, c0, 0, 0, 0, 0, 0)
    case _ 1n+fq _ _ _ _:
      lt.out(q)

# every way into S of l1 moves from the cube c0 (tw, rw its twist and raw)
def lt.below1(+l1: U32, t: Array<U32>, +tw: U32, +rw: U32, +c0: C.Cube, +b: Best) -> Array<U32> & Best:
  lt.go1(U32.to_nat(l1), 255n, YTry{}, lt.more(b, l1), S.sr.allowed(0, 6), QW{(t, 0), b},
    l1, l1, tw, rw, 6, Nil{}, 0, c0, 0, 0, 0, 0, 0)

# phase 1's ways in of l1 moves, if they can still do better
def lt.step1(go: Bool, t: Array<U32>, +b: Best, +l1: U32, +tw: U32, +rw: U32, +c0: C.Cube) -> Array<U32> & Best:
  match go:
    case False{}:
      (t, b)
    case True{}:
      lt.below1(l1, t, tw, rw, c0, b)

# phase 1's lengths l1.. (k of them)
def lt.ida1(k: Nat, r: Array<U32> & Best, +l1: U32, +tw: U32, +rw: U32, +c0: C.Cube) -> Array<U32> & Best:
  match k:
    case 0n:
      r
    case 1n+q:
      (t, +b) = r
      lt.ida1(q, lt.step1(lt.more(b, l1), t, b, l1, tw, rw, c0), U32.add(l1, 1), tw, rw, c0)

# The solve
# ---------

# the start: already in S (phase 2 at once), and phase 1's lengths from its
# distance on
def lt.start.go(home: Bool, t: Array<U32>, +h: U32, +tw: U32, +rw: U32, +c0: C.Cube) -> Array<U32> & Best:
  match home:
    case True{}:
      lt.ida1(12n, lt.leaf(t, c0, Nil{}, 0, 6, Best{None{}, 99, 0, 0}), 1, tw, rw, c0)
    case False{}:
      lt.ida1(12n, (t, Best{None{}, 99, 0, 0}), h, tw, rw, c0)

def lt.start(r: Array<U32> & U32, +tw: U32, +rw: U32, +c0: C.Cube) -> Array<U32> & Best:
  (t, +h) = r
  lt.start.go(U32.is_zero(h), t, h, tw, rw, c0)

# A cube's phase-1 bound: the larger of its two tables' distances (each a
# distance plus 1)
def lt.dist2(r: Array<U32> & U32, +a: U32) -> Array<U32> & U32:
  (t, +v) = r
  (t, U32.sub(U32.max(a, v), 1))

def lt.dist(r: Array<U32> & U32, +tw: U32, +rw: U32) -> Array<U32> & U32:
  (t, +a) = r
  lt.dist2(t[U32.add(lt.P1T(), U32.add(U32.mul(U32.shrn(rw, 11n), 2187), tw))], a)

# A short solution of the cube c0, twist tw, raw rw (lt.node)
def lt.solve(t: Array<U32>, +tw: U32, +rw: U32, +c0: C.Cube) -> Array<U32> & Best:
  lt.start(lt.dist(t[U32.add(lt.P1F(), rw)], tw, rw), tw, rw, c0)

# Phase 1's coordinates
# ---------------------

# the 495 sets of 4 of the 12 edge places, as bit masks, in increasing order
def lt.bits(n: Nat, +x: U32) -> U32:
  match n:
    case 0n:
      0
    case 1n+q:
      U32.add(U32.and(x, 1), lt.bits(q, U32.shrn(x, 1n)))

# (a loop, the masks so far last first in acc: a recursion 4096 deep is past
# what a browser's Web Worker allows)
def lt.masks.go(n: Nat, +x: U32, +acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      List.reverse(&2, U32, acc)
    case 1n+q:
      lt.masks.go(q, U32.add(x, 1), Bool.pick(List<&2, U32>, U32.is_eq(lt.bits(12n, x), 4), x <> acc, acc))

def lt.masks() -> List<&2, U32>:
  lt.masks.go(4096n, 0, Nil{})

def lt.mask(qs: List<&2, U32>) -> U32:
  match qs:
    case Nil{}:
      0
    case Con{+q, t}:
      U32.or(U32.shln(1, U32.to_nat(q)), lt.mask(t))

def lt.index(+x: U32, xs: List<&2, U32>, +i: U32) -> U32:
  match xs:
    case Nil{}:
      0
    case Con{+y, t}:
      Bool.pick(U32, U32.is_eq(x, y), i, lt.index(x, t, U32.add(i, 1)))

# a set's rank (0..494), given the masks
def lt.rank(+ms: List<&2, U32>, qs: List<&2, U32>) -> U32:
  lt.index(lt.mask(qs), ms, 0)

# the places of a mask's bits (from place q)
def lt.places(n: Nat, +x: U32, +q: U32) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      +rest = lt.places(p, U32.shrn(x, 1n), U32.add(q, 1))
      Bool.pick(List<&2, U32>, U32.is_eq(U32.and(x, 1), 1), q <> rest, rest)

def lt.eo(+c: C.Cube) -> List<&2, U32>:
  match c:
    case C.Cube{cp, co, ep, eo}:
      eo

# where the four slice edges (FR FL BL BR) are, ranked
def lt.u(+c: C.Cube) -> U32:
  lt.rank(lt.masks(), K.co.places([8, 9, 10, 11], lt.ep(c)))

# The node phase 1 starts from: (its twist, its raw: u * 2048 + flip)
type Node is Data:
  Node{+tw: U32, +rw: U32}

def lt.node(+c: C.Cube) -> Node:
  Node{Y.sy.twist(c), U32.add(U32.mul(lt.u(c), 2048), Y.sy.flip(lt.eo(c)))}

def lt.solve.node(t: Array<U32>, +n: Node, +c: C.Cube) -> Array<U32> & Best:
  match n:
    case Node{+tw, +rw}:
      lt.solve(t, tw, rw, c)

def lt.solve.cube(t: Array<U32>, +c: C.Cube) -> Array<U32> & Best:
  lt.solve.node(t, lt.node(c), c)

# The tables (made once, by DevTables.bend; Coord.bend's move tables first)
# -------------------------------------------------------------------------

def lt.fm.row(ms: List<&2, C.Cube>, +eo: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+m, t}:
      match m:
        case C.Cube{mcp, mco, mep, meo}:
          Y.sy.flip(C.cube.mul.o(eo, mep, meo, 2)) <> lt.fm.row(t, eo)

def lt.fill.fm(n: Nat, t: Array<U32>, +f: U32, +ms: List<&2, C.Cube>) -> Array<U32>:
  match n:
    case 0n:
      t
    case 1n+p:
      +row = lt.fm.row(ms, Y.sy.unflip(f))
      lt.fill.fm(p, K.co.write(row, t, U32.add(lt.FM(), U32.mul(f, 18))), U32.add(f, 1), ms)

def lt.u5.row(ms: List<&2, K.EMove>, +qs: List<&2, U32>, +ks: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+m, t}:
      match m:
        case K.EMove{to, eo}:
          lt.rank(ks, K.co.e.to(qs, to)) <> lt.u5.row(t, qs, ks)

def lt.fill.u5(xs: List<&2, U32>, t: Array<U32>, +u: U32, +ms: List<&2, K.EMove>, +ks: List<&2, U32>) -> Array<U32>:
  match xs:
    case Nil{}:
      t
    case Con{+x, rest}:
      +row = lt.u5.row(ms, lt.places(12n, x, 0), ks)
      lt.fill.u5(rest, K.co.write(row, t, U32.add(lt.U5M(), U32.mul(u, 18))), U32.add(u, 1), ms, ks)

# phase 1's distance tables, breadth first: which, its width, where its
# x's moves are
type P1 is Data:
  PF{}
  PT{}

def lt.p1.at(+k: P1) -> U32:
  match k:
    case PF{}:
      lt.P1F()
    case PT{}:
      lt.P1T()

def lt.p1.w(+k: P1) -> U32:
  match k:
    case PF{}:
      2048
    case PT{}:
      2187

def lt.p1.xm(+k: P1, +x: U32, +m: U32) -> U32:
  match k:
    case PF{}:
      U32.add(lt.FM(), U32.add(U32.mul(x, 18), m))
    case PT{}:
      U32.add(K.co.T.tw(), U32.add(U32.mul(x, 18), m))

type BP is Data:
  QE{}
  QM{}
  QX{}
  QY{}
  QC{}

# One level, as lt.bfs (phase 2's): every entry at distance d (word d + 1)
# gives its moves' unseen entries (word 0) d + 1 (word d + 2). Answers how
# many were new.
def lt.bfs1(
  +n: Nat, fuel: Nat, op: BP, ok: Bool, r: Array<U32> & U32, +k: P1, +d: U32,
  +e: U32, +x: U32, +y: U32, +m: U32, +x2: U32, +c: U32, +cnt: U32
) -> Array<U32> & U32:
  match n fuel op ok:
    case 0n _ _ _:
      (t, v) = r
      (t, cnt)
    case 1n+nq 0n _ _:
      (t, v) = r
      +en = U32.add(e, 1)
      lt.bfs1(nq, 127n, QE{}, True{}, t[U32.add(lt.p1.at(k), en)], k, d, en, 0, 0, 0, 0, 0, cnt)
    case 1n+nq 1n+fq QE{} _:
      (t, +v) = r
      +w = lt.p1.w(k)
      lt.bfs1(n, fq, QM{}, U32.is_eq(v, U32.add(d, 1)), (t, 0), k, d, e, U32.mod(e, w), U32.div(e, w), 0, 0, 0, cnt)
    case 1n+nq 1n+fq QM{} False{}:
      (t, z) = r
      +en = U32.add(e, 1)
      lt.bfs1(nq, 127n, QE{}, True{}, t[U32.add(lt.p1.at(k), en)], k, d, en, 0, 0, 0, 0, 0, cnt)
    case 1n+nq 1n+fq QM{} True{}:
      (t, z) = r
      lt.bfs1(n, fq, QX{}, True{}, t[lt.p1.xm(k, x, m)], k, d, e, x, y, m, 0, 0, cnt)
    case 1n+nq 1n+fq QX{} _:
      (t, +v) = r
      lt.bfs1(n, fq, QY{}, True{}, t[U32.add(lt.U5M(), U32.add(U32.mul(y, 18), m))], k, d, e, x, y, m, v, 0, cnt)
    case 1n+nq 1n+fq QY{} _:
      (t, +v) = r
      +cc = U32.add(U32.mul(v, lt.p1.w(k)), x2)
      lt.bfs1(n, fq, QC{}, True{}, t[U32.add(lt.p1.at(k), cc)], k, d, e, x, y, m, x2, cc, cnt)
    case 1n+nq 1n+fq QC{} _:
      (t, +v) = r
      +fresh = U32.is_zero(v)
      t2 = Array.set(U32, t, U32.add(lt.p1.at(k), c), Bool.pick(U32, fresh, U32.add(d, 2), v))
      +mn = U32.add(m, 1)
      lt.bfs1(n, fq, QM{}, U32.is_lt(mn, 18), (t2, 0), k, d, e, x, y, mn, 0, 0, U32.add(cnt, Bool.to_u32(fresh)))

def lt.level1(t: Array<U32>, +k: P1, +d: U32) -> Array<U32> & U32:
  lt.bfs1(U32.to_nat(U32.mul(495, lt.p1.w(k))), 127n, QE{}, True{}, t[lt.p1.at(k)], k, d, 0, 0, 0, 0, 0, 0, 0)

def lt.levels1(n: Nat, r: Array<U32> & U32, +k: P1, +d: U32) -> Array<U32>:
  match n:
    case 0n:
      (t, v) = r
      t
    case 1n+q:
      (t, +c) = r
      lt.levels1(q, lt.level1(t, k, d), k, U32.add(d, 1))

# zeros over words from k (n of them)
def lt.clear(n: Nat, t: Array<U32>, +k: U32) -> Array<U32>:
  match n:
    case 0n:
      t
    case 1n+q:
      lt.clear(q, Array.set(U32, t, k, 0), U32.add(k, 1))

# Every table but Coord.bend's: the flips' and the slice places' moves, phase
# 1's distances from S's entry (the slice home: u of {8, 9, 10, 11}, flip and
# twist 0), and phase 2's (lt.tables). Coord.bend's move tables must be in t.
def lt.all(t: Array<U32>) -> Array<U32>:
  +ks = lt.masks()
  +home = lt.rank(ks, [8, 9, 10, 11])
  t1 = lt.fill.u5(ks, lt.fill.fm(2048n, t, 0, K.co.moves()), 0, K.co.emoves(), ks)
  t2 = lt.clear(2102565n, t1, lt.P1F())
  t3 = Array.set(U32, Array.set(U32, t2, U32.add(lt.P1F(), U32.mul(home, 2048)), 1), U32.add(lt.P1T(), U32.mul(home, 2187)), 1)
  t4 = lt.levels1(14n, (lt.levels1(14n, (t3, 0), PF{}, 0), 0), PT{}, 0)
  lt.tables(lt.clear(1937680n, t4, lt.PC()))
