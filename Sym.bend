import Base
import ./Cube.bend as C
import ./Coord.bend as K

# The cube's symmetries, and the coordinates the faster solver's table is in.
#
# A symmetry is the whole cube turned in the hand: a cube S (Cube.bend's
# cubie level) with each piece where the turn takes it. A cube c seen after
# the turn is conj(c, S) = S^-1 * c * S. Turned so, a move is a move
# (LAWS.bend: sym_move), so c and conj(c, S) are as far from solved: a
# shortest solution of one, turned, is one of the other.
#
# Used here: the eight turns that keep the U-D axis (U4: 90 degrees about
# it; F2: 180 degrees about the F-B axis; sy.sym(s) = F2^(s / 4) * U4^(s % 4)),
# and URF3, 120 degrees about the URF-DBL corner diagonal, which takes the U-D
# axis to the R-L one, and that one to F-B.
#
# The coordinates (Kociemba's): flip, the flips of edges 0..10 in base 2
# (0..2047; edge 11's follows); slice, where the four U-D slice edges FR FL
# BL BR (8..11) are, in order (Coord.bend's arrangement of their places,
# 0..11879); raw = slice * 2048 + flip. The eight turns keep the U-D slice,
# so they act on raw; a class is a raw and its turned forms.
#
# Every def is prefixed `sy.`.

# The turns
# ---------

def sy.U4() -> C.Cube:
  C.Cube{[3, 0, 1, 2, 7, 4, 5, 6], [0, 0, 0, 0, 0, 0, 0, 0],
         [3, 0, 1, 2, 7, 4, 5, 6, 11, 8, 9, 10], [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1]}

def sy.F2() -> C.Cube:
  C.Cube{[5, 4, 7, 6, 1, 0, 3, 2], [0, 0, 0, 0, 0, 0, 0, 0],
         [6, 5, 4, 7, 2, 1, 0, 3, 9, 8, 11, 10], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]}

def sy.URF3() -> C.Cube:
  C.Cube{[0, 4, 5, 1, 3, 7, 6, 2], [1, 2, 1, 2, 2, 1, 2, 1],
         [1, 8, 5, 9, 3, 11, 7, 10, 0, 4, 6, 2], [1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1]}

# A cube's inverse: each piece back where it came from, turned back
def sy.inv.o(+xo: List<&2, U32>, ip: List<&2, U32>, +k: U32) -> List<&2, U32>:
  match ip:
    case Nil{}:
      Nil{}
    case Con{+j, t}:
      U32.mod(U32.sub(k, C.cube.at(xo, j)), k) <> sy.inv.o(xo, t, k)

def sy.inv.mk(+icp: List<&2, U32>, +co: List<&2, U32>, +iep: List<&2, U32>, +eo: List<&2, U32>) -> C.Cube:
  C.Cube{icp, sy.inv.o(co, icp, 3), iep, sy.inv.o(eo, iep, 2)}

def sy.inv(+c: C.Cube) -> C.Cube:
  match c:
    case C.Cube{cp, co, ep, eo}:
      sy.inv.mk(K.co.inv(cp, K.co.range(8n)), co, K.co.inv(ep, K.co.range(12n)), eo)

# c seen after the turn s: s^-1 * c * s
def sy.conj(+c: C.Cube, +s: C.Cube) -> C.Cube:
  C.cube.mul(C.cube.mul(sy.inv(s), c), s)

# The eight turns that keep the U-D axis
type Sym is Data:
  S0{}
  S1{}
  S2{}
  S3{}
  S4{}
  S5{}
  S6{}
  S7{}

def sy.num(s: Sym) -> U32:
  match s:
    case S0{}:
      0
    case S1{}:
      1
    case S2{}:
      2
    case S3{}:
      3
    case S4{}:
      4
    case S5{}:
      5
    case S6{}:
      6
    case S7{}:
      7

# turn number s (0..7): F2^(s / 4) * U4^(s % 4)
def sy.sym.n(+s: U32) -> C.Cube:
  C.cube.mul(C.cube.pow(sy.F2(), U32.to_nat(U32.shrn(s, 2n))), C.cube.pow(sy.U4(), U32.to_nat(U32.and(s, 3))))

def sy.sym(s: Sym) -> C.Cube:
  sy.sym.n(sy.num(s))

# The move a turned move is: the first of the 18 that c is (18 if none)
def sy.find.go(n: Nat, +c: C.Cube, +m: U32) -> U32:
  match n:
    case 0n:
      18
    case 1n+p:
      Bool.pick(U32, C.cube.eq(C.cube.move(m), c), m, sy.find.go(p, c, U32.add(m, 1)))

def sy.find(+c: C.Cube) -> U32:
  sy.find.go(18n, c, 0)

# move m turned by symmetry number s, and by URF3
def sy.cm.n(+m: U32, +s: U32) -> U32:
  sy.find(sy.conj(C.cube.move(m), sy.sym.n(s)))

def sy.cm(+m: U32, s: Sym) -> U32:
  sy.cm.n(m, sy.num(s))

def sy.cmu(+m: U32) -> U32:
  sy.find(sy.conj(C.cube.move(m), sy.URF3()))

# The moves ms, each turned by URF3
def sy.urf.ms(ms: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+m, t}:
      sy.cmu(m) <> sy.urf.ms(t)

# The coordinates
# ---------------

def sy.flip.go(n: Nat, eo: List<&2, U32>, +acc: U32) -> U32:
  match n eo:
    case 1n+p Con{+x, t}:
      sy.flip.go(p, t, U32.add(U32.mul(acc, 2), x))
    case _ _:
      acc

# edges 0..10's flips, in base 2
def sy.flip(eo: List<&2, U32>) -> U32:
  sy.flip.go(11n, eo, 0)

def sy.unflip.go(n: Nat, +f: U32, acc: List<&2, U32>, +sum: U32) -> List<&2, U32>:
  match n:
    case 0n:
      List.append(&2, U32, acc, [U32.and(sum, 1)])
    case 1n+p:
      +x = U32.and(f, 1)
      sy.unflip.go(p, U32.shrn(f, 1n), x <> acc, U32.add(sum, x))

# the twelve flips of flip f
def sy.unflip(+f: U32) -> List<&2, U32>:
  sy.unflip.go(11n, f, Nil{}, 0)

def sy.slice.pieces() -> List<&2, U32>:
  [8, 9, 10, 11]

# where FR FL BL BR are, as an arrangement
def sy.slice(+ep: List<&2, U32>) -> U32:
  K.co.arr(K.co.places(sy.slice.pieces(), ep))

# the places of FR FL BL BR in arrangement a
def sy.unslice(+a: U32) -> List<&2, U32>:
  K.co.unarr.places(K.co.unarr.digits(4n, a, 9, Nil{}), K.co.range(12n))

def sy.ep.go(n: Nat, +qs: List<&2, U32>, +i: U32, +j: U32) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      +k = K.co.index(i, qs, 0)
      +s = U32.is_lt(k, 4)
      Bool.pick(U32, s, U32.add(k, 8), j) <> sy.ep.go(p, qs, U32.add(i, 1), Bool.pick(U32, s, j, U32.add(j, 1)))

# A cube with raw's slice and flips (the other edges in order, corners home)
def sy.ecube(+raw: U32) -> C.Cube:
  C.Cube{[0, 1, 2, 3, 4, 5, 6, 7], [0, 0, 0, 0, 0, 0, 0, 0],
         sy.ep.go(12n, sy.unslice(U32.shrn(raw, 11n)), 0, 0), sy.unflip(U32.and(raw, 2047))}

def sy.raw(+c: C.Cube) -> U32:
  match c:
    case C.Cube{cp, co, ep, eo}:
      U32.add(U32.mul(sy.slice(ep), 2048), sy.flip(eo))

# raw turned: the raw of s * e * s^-1 (so that raw is the result turned by s)
def sy.raw.conj(+raw: U32, +s: U32) -> U32:
  +t = sy.sym.n(s)
  sy.raw(C.cube.mul(C.cube.mul(t, sy.ecube(raw)), sy.inv(t)))

def sy.twist(+c: C.Cube) -> U32:
  match c:
    case C.Cube{cp, co, ep, eo}:
      K.co.twist(co)

# twist t turned by s: the twist of s^-1 * T * s, T a cube with twist t
def sy.twist.conj(+t: U32, +s: U32) -> U32:
  sy.twist(sy.conj(C.Cube{[0, 1, 2, 3, 4, 5, 6, 7], K.co.untwist(t),
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]}, sy.sym.n(s)))
