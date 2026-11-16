import Base
import ./Cube.bend as C
import ./Coord.bend as K
import ./Search.bend as S
import ./Sym.bend as Y
import ./Kc.bend as T

# The faster search: IDA* (Search.bend's, with its move rules) over
# Kc.bend's tables. A node's distance bound is the largest of four exact
# distances of parts of it: its corners (Coord.bend), and its flip, slice and
# twist as it is and turned by URF3 and URF3^2 (Kc.bend). Each is a true
# distance of a part, so never more than the cube's own: the first bound
# with a solution gives a shortest one.
#
# A node: cp, t0 its corners (permutation rank, twist); then for each of the
# three ways it is seen, its twist and raw (Sym.bend): t0 r0, t1 r1, t2 r2.
# A move m is m on the cube as it is, sy.cmu(m) turned once, twice.
#
# Every def is prefixed `op.`.

# What a move from a node gives: cut (some distance passes the bound),
# solved, or a node to search below
type Kid is Data:
  KCut{}
  KGoal{}
  KNode{+cp: U32, +t0: U32, +r0: U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32}

# A child, a word read at a time
# ------------------------------

def op.raw(+f: U32, +s: U32) -> U32:
  U32.add(U32.mul(s, 2048), f)

# the last axis's distance read: cut, solved, or the child
def op.k27(go: Bool, goal: Bool, +cp: U32, +a0: U32, +b0: U32, +a1: U32, +b1: U32, +a2: U32, +b2: U32) -> Kid:
  match go goal:
    case False{} _:
      KCut{}
    case True{} True{}:
      KGoal{}
    case True{} False{}:
      KNode{cp, a0, b0, a1, b1, a2, b2}

def op.k26(r: Array<U32> & U32, +tc: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32, +a1: U32, +b1: U32, +a2: U32, +b2: U32) -> Array<U32> & Kid:
  (t, +w) = r
  +h = T.kc.nib(w, U32.and(tc, 7))
  (t, op.k27(U32.is_lt(h, bud), U32.is_zero(U32.max(h, hm)), cp, a0, b0, a1, b1, a2, b2))

def op.k25(r: Array<U32> & U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32, +a1: U32, +b1: U32, +a2: U32, +b2: U32, +cl: U32) -> Array<U32> & Kid:
  (t, +tc) = r
  op.k26(t[T.kc.word(U32.shrn(cl, 4n), tc)], tc, bud, hm, cp, a0, b0, a1, b1, a2, b2)

def op.k24(r: Array<U32> & U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32, +a1: U32, +b1: U32, +a2: U32, +b2: U32) -> Array<U32> & Kid:
  (t, +cl) = r
  op.k25(t[U32.add(T.kc.TC(), U32.add(U32.mul(a2, 8), U32.and(cl, 7)))], bud, hm, cp, a0, b0, a1, b1, a2, b2, cl)

def op.k23(r: Array<U32> & U32, +f2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32, +a1: U32, +b1: U32, +a2: U32) -> Array<U32> & Kid:
  (t, +s2) = r
  +b2 = op.raw(f2, s2)
  op.k24(t[U32.add(T.kc.CL(), b2)], bud, hm, cp, a0, b0, a1, b1, a2, b2)

def op.k22(r: Array<U32> & U32, +r2: U32, +m2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32, +a1: U32, +b1: U32, +a2: U32) -> Array<U32> & Kid:
  (t, +f2) = r
  op.k23(t[U32.add(T.kc.SM(), U32.add(U32.mul(U32.shrn(r2, 11n), 18), m2))], f2, bud, hm, cp, a0, b0, a1, b1, a2)

def op.k21(r: Array<U32> & U32, +r2: U32, +m2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32, +a1: U32, +b1: U32) -> Array<U32> & Kid:
  (t, +a2) = r
  op.k22(t[U32.add(T.kc.FM(), U32.add(U32.mul(U32.and(r2, 2047), 18), m2))], r2, m2, bud, hm, cp, a0, b0, a1, b1, a2)

def op.k20(r: Array<U32> & U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32, +a1: U32, +b1: U32) -> Array<U32> & Kid:
  (t, +m2) = r
  op.k21(t[U32.add(K.co.T.tw(), U32.add(U32.mul(t2, 18), m2))], r2, m2, bud, hm, cp, a0, b0, a1, b1)

def op.k19(go: Bool, t: Array<U32>, +m1: U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32, +a1: U32, +b1: U32) -> Array<U32> & Kid:
  match go:
    case False{}:
      (t, KCut{})
    case True{}:
      op.k20(t[U32.add(T.kc.CMU(), m1)], t2, r2, bud, hm, cp, a0, b0, a1, b1)

def op.k18(r: Array<U32> & U32, +tc: U32, +m1: U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32, +a1: U32, +b1: U32) -> Array<U32> & Kid:
  (t, +w) = r
  +h = T.kc.nib(w, U32.and(tc, 7))
  op.k19(U32.is_lt(h, bud), t, m1, t2, r2, bud, U32.max(h, hm), cp, a0, b0, a1, b1)

def op.k17(r: Array<U32> & U32, +cl: U32, +m1: U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32, +a1: U32, +b1: U32) -> Array<U32> & Kid:
  (t, +tc) = r
  op.k18(t[T.kc.word(U32.shrn(cl, 4n), tc)], tc, m1, t2, r2, bud, hm, cp, a0, b0, a1, b1)

def op.k16(r: Array<U32> & U32, +m1: U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32, +a1: U32, +b1: U32) -> Array<U32> & Kid:
  (t, +cl) = r
  op.k17(t[U32.add(T.kc.TC(), U32.add(U32.mul(a1, 8), U32.and(cl, 7)))], cl, m1, t2, r2, bud, hm, cp, a0, b0, a1, b1)

def op.k15(r: Array<U32> & U32, +f1: U32, +m1: U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32, +a1: U32) -> Array<U32> & Kid:
  (t, +s1) = r
  +b1 = op.raw(f1, s1)
  op.k16(t[U32.add(T.kc.CL(), b1)], m1, t2, r2, bud, hm, cp, a0, b0, a1, b1)

def op.k14(r: Array<U32> & U32, +r1: U32, +m1: U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32, +a1: U32) -> Array<U32> & Kid:
  (t, +f1) = r
  op.k15(t[U32.add(T.kc.SM(), U32.add(U32.mul(U32.shrn(r1, 11n), 18), m1))], f1, m1, t2, r2, bud, hm, cp, a0, b0, a1)

def op.k13(r: Array<U32> & U32, +r1: U32, +m1: U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32) -> Array<U32> & Kid:
  (t, +a1) = r
  op.k14(t[U32.add(T.kc.FM(), U32.add(U32.mul(U32.and(r1, 2047), 18), m1))], r1, m1, t2, r2, bud, hm, cp, a0, b0, a1)

def op.k12(r: Array<U32> & U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32) -> Array<U32> & Kid:
  (t, +m1) = r
  op.k13(t[U32.add(K.co.T.tw(), U32.add(U32.mul(t1, 18), m1))], r1, m1, t2, r2, bud, hm, cp, a0, b0)

def op.k11(go: Bool, t: Array<U32>, +m: U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32) -> Array<U32> & Kid:
  match go:
    case False{}:
      (t, KCut{})
    case True{}:
      op.k12(t[U32.add(T.kc.CMU(), m)], t1, r1, t2, r2, bud, hm, cp, a0, b0)

def op.k10(r: Array<U32> & U32, +tc: U32, +m: U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32) -> Array<U32> & Kid:
  (t, +w) = r
  +h = T.kc.nib(w, U32.and(tc, 7))
  op.k11(U32.is_lt(h, bud), t, m, t1, r1, t2, r2, bud, U32.max(h, hm), cp, a0, b0)

def op.k9(r: Array<U32> & U32, +cl: U32, +m: U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32) -> Array<U32> & Kid:
  (t, +tc) = r
  op.k10(t[T.kc.word(U32.shrn(cl, 4n), tc)], tc, m, t1, r1, t2, r2, bud, hm, cp, a0, b0)

def op.k8(r: Array<U32> & U32, +m: U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32, +b0: U32) -> Array<U32> & Kid:
  (t, +cl) = r
  op.k9(t[U32.add(T.kc.TC(), U32.add(U32.mul(a0, 8), U32.and(cl, 7)))], cl, m, t1, r1, t2, r2, bud, hm, cp, a0, b0)

def op.k7(r: Array<U32> & U32, +f0: U32, +m: U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32) -> Array<U32> & Kid:
  (t, +s0) = r
  +b0 = op.raw(f0, s0)
  op.k8(t[U32.add(T.kc.CL(), b0)], m, t1, r1, t2, r2, bud, hm, cp, a0, b0)

def op.k6(r: Array<U32> & U32, +r0: U32, +m: U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32) -> Array<U32> & Kid:
  (t, +f0) = r
  op.k7(t[U32.add(T.kc.SM(), U32.add(U32.mul(U32.shrn(r0, 11n), 18), m))], f0, m, t1, r1, t2, r2, bud, hm, cp, a0)

def op.k5(go: Bool, t: Array<U32>, +r0: U32, +m: U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32, +bud: U32, +hm: U32, +cp: U32, +a0: U32) -> Array<U32> & Kid:
  match go:
    case False{}:
      (t, KCut{})
    case True{}:
      op.k6(t[U32.add(T.kc.FM(), U32.add(U32.mul(U32.and(r0, 2047), 18), m))], r0, m, t1, r1, t2, r2, bud, hm, cp, a0)

def op.k4(r: Array<U32> & U32, +ci: U32, +r0: U32, +m: U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32, +bud: U32, +cp: U32, +a0: U32) -> Array<U32> & Kid:
  (t, +w) = r
  +h = K.co.nib(w, ci)
  op.k5(U32.is_lt(h, bud), t, r0, m, t1, r1, t2, r2, bud, h, cp, a0)

def op.k3(r: Array<U32> & U32, +cp: U32, +r0: U32, +m: U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32, +bud: U32) -> Array<U32> & Kid:
  (t, +a0) = r
  +ci = U32.add(U32.mul(cp, 2187), a0)
  op.k4(t[U32.add(K.co.T.pc(), U32.shrn(ci, 3n))], ci, r0, m, t1, r1, t2, r2, bud, cp, a0)

def op.k2(r: Array<U32> & U32, +t0: U32, +r0: U32, +m: U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32, +bud: U32) -> Array<U32> & Kid:
  (t, +cp) = r
  op.k3(t[U32.add(K.co.T.tw(), U32.add(U32.mul(t0, 18), m))], cp, r0, m, t1, r1, t2, r2, bud)

# move m from a node with bud moves left: the corners first, then each axis,
# stopping at the first distance that is bud or more
def op.kid(t: Array<U32>, +cp: U32, +t0: U32, +r0: U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32, +m: U32, +bud: U32) -> Array<U32> & Kid:
  op.k2(t[U32.add(K.co.T.cp(), U32.add(U32.mul(cp, 18), m))], t0, r0, m, t1, r1, t2, r2, bud)

# A node's distance bound
# -----------------------

def op.h.ax3(r: Array<U32> & U32, +tc: U32, +h: U32) -> Array<U32> & U32:
  (t, +w) = r
  (t, U32.max(h, T.kc.nib(w, U32.and(tc, 7))))

def op.h.ax2(r: Array<U32> & U32, +cl: U32, +h: U32) -> Array<U32> & U32:
  (t, +tc) = r
  op.h.ax3(t[T.kc.word(U32.shrn(cl, 4n), tc)], tc, h)

def op.h.ax1(r: Array<U32> & U32, +tw: U32, +h: U32) -> Array<U32> & U32:
  (t, +cl) = r
  op.h.ax2(t[U32.add(T.kc.TC(), U32.add(U32.mul(tw, 8), U32.and(cl, 7)))], cl, h)

# the larger of h and the distance of (twist tw, raw)
def op.h.ax(r: Array<U32> & U32, +tw: U32, +raw: U32) -> Array<U32> & U32:
  (t, +h) = r
  op.h.ax1(t[U32.add(T.kc.CL(), raw)], tw, h)

def op.h.c(r: Array<U32> & U32, +ci: U32) -> Array<U32> & U32:
  (t, +w) = r
  (t, K.co.nib(w, ci))

def op.h(t: Array<U32>, +cp: U32, +t0: U32, +r0: U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32) -> Array<U32> & U32:
  +ci = U32.add(U32.mul(cp, 2187), t0)
  op.h.ax(op.h.ax(op.h.ax(op.h.c(t[U32.add(K.co.T.pc(), U32.shrn(ci, 3n))], ci), t0, r0), t1, r1), t2, r2)

# The search
# ----------

type OOp is Data:
  OTry{}
  OKid{}
  OBack{}

# The array and the result so far; a move's child just made; a child's answer
type Carry is Type:
  CA{t: Array<U32>, +res: S.Res}
  CK{r: Array<U32> & Kid, +res: S.Res}
  CR{r: Array<U32> & S.Res}

def op.out(c: Carry) -> Array<U32> & S.Res:
  match c:
    case CA{t, res}:
      (t, res)
    case CK{r, res}:
      (t, k) = r
      (t, res)
    case CR{r}:
      r

# The search below a node, d moves left (bud: d as a U32), as Search.bend's:
#   OTry  more: m < 18 and nothing found; ok: m may follow lf
#   OKid  move m's child made: cut, solved, or a node to search below
#   OBack the child's search done: the next move
def op.go(
  +d: Nat, fuel: Nat, op: OOp, more: Bool, ok: Bool, c: Carry, +bud: U32,
  +cp: U32, +t0: U32, +r0: U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32, +lf: U32, +path: List<&2, U32>, +m: U32
) -> Array<U32> & S.Res:
  match d fuel op more ok c:
    case _ 0n _ _ _ _:
      op.out(c)
    case _ 1n+fq OTry{} False{} _ _:
      op.out(c)
    case _ 1n+fq OTry{} True{} False{} CA{t, +res}:
      +mn = U32.add(m, 1)
      op.go(d, fq, OTry{}, Bool.and(U32.is_lt(mn, 18), Bool.not(S.sr.found(res))), S.sr.allowed(mn, lf), CA{t, res}, bud,
        cp, t0, r0, t1, r1, t2, r2, lf, path, mn)
    case _ 1n+fq OTry{} True{} True{} CA{t, +res}:
      op.go(d, fq, OKid{}, True{}, True{}, CK{op.kid(t, cp, t0, r0, t1, r1, t2, r2, m, bud), res}, bud,
        cp, t0, r0, t1, r1, t2, r2, lf, path, m)
    case 0n 1n+fq OKid{} _ _ CK{r, +res}:
      (t, k) = r
      match k:
        case KGoal{}:
          op.go(d, fq, OTry{}, False{}, False{}, CA{t, S.sr.win(res, m <> path)}, bud,
            cp, t0, r0, t1, r1, t2, r2, lf, path, m)
        case _:
          +mn = U32.add(m, 1)
          op.go(d, fq, OTry{}, U32.is_lt(mn, 18), S.sr.allowed(mn, lf), CA{t, S.sr.count(res)}, bud,
            cp, t0, r0, t1, r1, t2, r2, lf, path, mn)
    case 1n+dq 1n+fq OKid{} _ _ CK{r, +res}:
      (t, k) = r
      match k:
        case KCut{}:
          +mn = U32.add(m, 1)
          op.go(d, fq, OTry{}, U32.is_lt(mn, 18), S.sr.allowed(mn, lf), CA{t, S.sr.count(res)}, bud,
            cp, t0, r0, t1, r1, t2, r2, lf, path, mn)
        case KGoal{}:
          op.go(d, fq, OTry{}, False{}, False{}, CA{t, S.sr.win(res, m <> path)}, bud,
            cp, t0, r0, t1, r1, t2, r2, lf, path, m)
        case KNode{+c2, +a0, +b0, +a1, +b1, +a2, +b2}:
          +f = S.sr.face(m)
          op.go(d, fq, OBack{}, True{}, True{},
            CR{op.go(dq, 255n, OTry{}, True{}, S.sr.allowed(0, f), CA{t, S.sr.count(res)}, U32.sub(bud, 1),
              c2, a0, b0, a1, b1, a2, b2, f, m <> path, 0)}, bud,
            cp, t0, r0, t1, r1, t2, r2, lf, path, m)
    case _ 1n+fq OBack{} _ _ CR{r}:
      (t, +res) = r
      +mn = U32.add(m, 1)
      op.go(d, fq, OTry{}, Bool.and(U32.is_lt(mn, 18), Bool.not(S.sr.found(res))), S.sr.allowed(mn, lf), CA{t, res}, bud,
        cp, t0, r0, t1, r1, t2, r2, lf, path, mn)
    case _ 1n+fq _ _ _ _:
      op.out(c)

# A node: its seven coordinates
type Node is Data:
  Node{+cp: U32, +t0: U32, +r0: U32, +t1: U32, +r1: U32, +t2: U32, +r2: U32}

# A search of depth d below a node (path its moves so far, last first; lf
# its last face, 6 for none)
def op.below(+d: Nat, t: Array<U32>, +n: Node, +lf: U32, +path: List<&2, U32>) -> Array<U32> & S.Res:
  match n:
    case Node{cp, t0, r0, t1, r1, t2, r2}:
      op.go(d, 255n, OTry{}, True{}, S.sr.allowed(0, lf), CA{t, S.Res{None{}, 0}}, U32.from_nat(d),
        cp, t0, r0, t1, r1, t2, r2, lf, path, 0)

def op.bound(t: Array<U32>, +n: Node) -> Array<U32> & U32:
  match n:
    case Node{cp, t0, r0, t1, r1, t2, r2}:
      op.h(t, cp, t0, r0, t1, r1, t2, r2)

# The node of a cube, from its three views (as it is, turned once, twice)
def op.cp(+c: C.Cube) -> U32:
  match c:
    case C.Cube{cp, co, ep, eo}:
      K.co.rank(cp)

def op.node(+c0: C.Cube, +c1: C.Cube, +c2: C.Cube) -> Node:
  Node{op.cp(c0), Y.sy.twist(c0), Y.sy.raw(c0), Y.sy.twist(c1), Y.sy.raw(c1), Y.sy.twist(c2), Y.sy.raw(c2)}

# the three views of the cube the moves ms make from solved
type View is Data:
  View{+c0: C.Cube, +c1: C.Cube, +c2: C.Cube}

def op.view(+ms: List<&2, U32>) -> View:
  +u = Y.sy.urf.ms(ms)
  View{C.cube.apply(ms, C.cube.solved()), C.cube.apply(u, C.cube.solved()), C.cube.apply(Y.sy.urf.ms(u), C.cube.solved())}

def op.view.move(+v: View, +m: U32) -> View:
  match v:
    case View{c0, c1, c2}:
      +m1 = Y.sy.cmu(m)
      View{C.cube.mul(c0, C.cube.move(m)), C.cube.mul(c1, C.cube.move(m1)), C.cube.mul(c2, C.cube.move(Y.sy.cmu(m1)))}

def op.view.node(+v: View) -> Node:
  match v:
    case View{c0, c1, c2}:
      op.node(c0, c1, c2)

# The prefixes: the canonical sequences of n moves from v, as in Par.bend
type Pre is Data:
  Pre{+ms: List<&2, U32>, +n: Node, +lf: U32}

def op.gen(+n: Nat, k: Nat, ok: Bool, +v: View, +ms: List<&2, U32>, +lf: U32, +m: U32) -> List<&2, Pre>:
  match n k ok:
    case 0n _ _:
      [Pre{List.reverse(&2, U32, ms), op.view.node(v), lf}]
    case 1n+q 0n _:
      Nil{}
    case 1n+q 1n+kq True{}:
      +f = S.sr.face(m)
      +mn = U32.add(m, 1)
      List.append(&2, Pre, op.gen(q, 18n, S.sr.allowed(0, f), op.view.move(v, m), m <> ms, f, 0),
        op.gen(n, kq, S.sr.allowed(mn, lf), v, ms, lf, mn))
    case 1n+q 1n+kq False{}:
      +mn = U32.add(m, 1)
      op.gen(n, kq, S.sr.allowed(mn, lf), v, ms, lf, mn)

def op.prefixes(+n: Nat, +v: View) -> List<&2, Pre>:
  op.gen(n, 18n, True{}, v, Nil{}, 6, 0)

# A lane's prefixes, one after the other, at bound b (b - 3 moves left
# below each), until one finds a solution
def op.add2(t: Array<U32>, res: S.Res, +acc: S.Res) -> Array<U32> & S.Res:
  match res acc:
    case S.Res{f, n} S.Res{g, k}:
      (t, S.Res{f, U32.add(n, k)})

def op.add(r: Array<U32> & S.Res, +acc: S.Res) -> Array<U32> & S.Res:
  (t, res) = r
  op.add2(t, res, acc)

def op.one(stop: Bool, +p: Pre, t: Array<U32>, +b: U32, +acc: S.Res) -> Array<U32> & S.Res:
  match stop p:
    case True{} _:
      (t, acc)
    case False{} Pre{ms, n, lf}:
      op.add(op.below(U32.to_nat(U32.sub(b, 3)), t, n, lf, List.reverse(&2, U32, ms)), acc)

def op.lane(ps: List<&2, Pre>, r: Array<U32> & S.Res, +b: U32) -> Array<U32> & S.Res:
  match ps:
    case Nil{}:
      r
    case Con{+p, rest}:
      (t, +acc) = r
      op.lane(rest, op.one(S.sr.found(acc), p, t, b, acc), b)

# The prefixes dealt to 2^(d+1) lanes, alternately (as a tree, like the lanes)
type W is Data:
  WLeaf{+ps: List<&2, Pre>}
  WNode{+l: W, +r: W}

def op.alt(xs: List<&2, Pre>, a: List<&2, Pre>, b: List<&2, Pre>) -> List<&2, Pre> & List<&2, Pre>:
  match xs:
    case Nil{}:
      (List.reverse(&2, Pre, a), List.reverse(&2, Pre, b))
    case Con{+x, t}:
      op.alt(t, b, x <> a)

def op.deal.go(+d: Nat, r: List<&2, Pre> & List<&2, Pre>) -> W:
  match d:
    case 0n:
      (a, b) = r
      WNode{WLeaf{a}, WLeaf{b}}
    case 1n+q:
      (a, b) = r
      WNode{op.deal.go(q, op.alt(a, Nil{}, Nil{})), op.deal.go(q, op.alt(b, Nil{}, Nil{}))}

def op.deal(+d: Nat, xs: List<&2, Pre>) -> W:
  op.deal.go(d, op.alt(xs, Nil{}, Nil{}))

# the left answer's solution if it has one, else the right's; nodes summed
def op.pick(rx: S.Res, ry: S.Res) -> S.Res:
  match rx ry:
    case S.Res{Some{ms}, n} S.Res{g, k}:
      S.Res{Some{ms}, U32.add(n, k)}
    case S.Res{None{}, n} S.Res{g, k}:
      S.Res{g, U32.add(n, k)}
