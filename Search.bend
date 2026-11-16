import Base
import ./Cube.bend as C
import ./Coord.bend as K

# IDA* (Korf, 1985): depth-first searches with a growing bound on the moves,
# each cutting a branch as soon as the moves made plus a distance bound
# (Coord.bend's three tables, their maximum) pass the bound. The first bound
# with a solution gives a shortest one: every shorter sequence was looked at
# under a smaller bound (or cut, which a true lower bound never does wrongly).
#
# A node is its coordinates: cp, tw (the corners) and ea, eb (the edge sets A
# and B, ar * 64 + fl). Moves are tried in order, skipping a turn of the face
# just turned, and of a face's opposite before it (U D and D U are the same,
# only U D is tried): no shortest sequence is skipped, as each has a form so.
#
# Every def is prefixed `sr.`.

# What a search found: a shortest solution from where it started, if any; and
# how many nodes it made
type Res is Data:
  Res{+found: Maybe<&2, List<&2, U32>>, +nodes: U32}

def sr.found(+r: Res) -> Bool:
  match r:
    case Res{f, n}:
      Maybe.is_some(&2, List<&2, U32>, f)

def sr.count(+r: Res) -> Res:
  match r:
    case Res{f, n}:
      Res{f, U32.add(n, 1)}

def sr.win(+r: Res, +path: List<&2, U32>) -> Res:
  match r:
    case Res{f, n}:
      Res{Some{List.reverse(&2, U32, path)}, U32.add(n, 1)}

# move m's face (m / 3, for m < 18)
def sr.face(+m: U32) -> U32:
  U32.shrn(U32.mul(m, 11), 5n)

# whether m may follow a turn of face lf (6: no turn yet)
def sr.allowed(+m: U32, +lf: U32) -> Bool:
  +f = sr.face(m)
  Bool.and(U32.is_ne(f, lf), U32.is_ne(U32.add(f, 3), lf))

def sr.max3(+a: U32, +b: U32, +c: U32) -> U32:
  U32.max(a, U32.max(b, c))

# A child's edge entry from its arrangement's move v (the flips to xor above bit 20)
def sr.edge(+e: U32, +v: U32) -> U32:
  U32.add(U32.shln(U32.and(v, 1048575), 6n), U32.xor(U32.and(e, 63), U32.shrn(v, 20n)))

# What a step is about to do
type SOp is Data:
  STry{}
  SR1{}
  SR2{}
  SR3{}
  SR4{}
  SR5{}
  SR6{}
  SR7{}
  SDec{}
  SBack{}

# The array, and the word last read with the result so far; or a child's answer
type Carry is Type:
  CW{r: Array<U32> & U32, +res: Res}
  CR{r: Array<U32> & Res}

def sr.out(c: Carry) -> Array<U32> & Res:
  match c:
    case CW{r, res}:
      (t, v) = r
      (t, res)
    case CR{r}:
      r

# The search below a node, d moves left (bud: d as a U32). Each step reads at
# most one word of T (the carry), and goes on as op says; more, ok, cut, goal
# are what the step before found, for this one to match on:
#   STry  more: m < 18 and nothing found; ok: m may follow lf
#   SDec  cut: the child's bound passes what is left; goal: the child is solved
# The node: cp, tw, ea, eb; lf its last move's face; path its moves, last
# first. m: the move tried; its child: cp2, tw2, ea2, eb2, and hc, ha (two of
# the child's three distances).
def sr.go(
  +d: Nat, fuel: Nat, op: SOp, more: Bool, ok: Bool, cut: Bool, goal: Bool, c: Carry,
  +bud: U32, +cp: U32, +tw: U32, +ea: U32, +eb: U32, +lf: U32, +path: List<&2, U32>, +m: U32,
  +cp2: U32, +tw2: U32, +ea2: U32, +eb2: U32, +hc: U32, +ha: U32
) -> Array<U32> & Res:
  match d fuel op more ok cut goal c:
    case _ 0n _ _ _ _ _ _:
      sr.out(c)
    case _ 1n+fq STry{} False{} _ _ _ _:
      # every move tried, or a solution found: this node is done
      sr.out(c)
    case _ 1n+fq STry{} True{} False{} _ _ CW{r, +res}:
      # m may not follow lf: the next
      +mn = U32.add(m, 1)
      sr.go(d, fq, STry{}, Bool.and(U32.is_lt(mn, 18), Bool.not(sr.found(res))), sr.allowed(mn, lf), False{}, False{}, CW{r, res},
        bud, cp, tw, ea, eb, lf, path, mn, 0, 0, 0, 0, 0, 0)
    case _ 1n+fq STry{} True{} True{} _ _ CW{r, +res}:
      # move m: cp's move first
      (t, z) = r
      sr.go(d, fq, SR1{}, True{}, True{}, False{}, False{}, CW{t[U32.add(K.co.T.cp(), U32.add(U32.mul(cp, 18), m))], res},
        bud, cp, tw, ea, eb, lf, path, m, 0, 0, 0, 0, 0, 0)
    case _ 1n+fq SR1{} _ _ _ _ CW{r, +res}:
      (t, +v) = r
      sr.go(d, fq, SR2{}, True{}, True{}, False{}, False{}, CW{t[U32.add(K.co.T.tw(), U32.add(U32.mul(tw, 18), m))], res},
        bud, cp, tw, ea, eb, lf, path, m, v, 0, 0, 0, 0, 0)
    case _ 1n+fq SR2{} _ _ _ _ CW{r, +res}:
      (t, +v) = r
      sr.go(d, fq, SR3{}, True{}, True{}, False{}, False{}, CW{t[U32.add(K.co.T.e(), U32.add(U32.mul(U32.shrn(ea, 6n), 18), m))], res},
        bud, cp, tw, ea, eb, lf, path, m, cp2, v, 0, 0, 0, 0)
    case _ 1n+fq SR3{} _ _ _ _ CW{r, +res}:
      (t, +v) = r
      sr.go(d, fq, SR4{}, True{}, True{}, False{}, False{}, CW{t[U32.add(K.co.T.e(), U32.add(U32.mul(U32.shrn(eb, 6n), 18), m))], res},
        bud, cp, tw, ea, eb, lf, path, m, cp2, tw2, sr.edge(ea, v), 0, 0, 0)
    case _ 1n+fq SR4{} _ _ _ _ CW{r, +res}:
      (t, +v) = r
      +ci = U32.add(U32.mul(cp2, 2187), tw2)
      sr.go(d, fq, SR5{}, True{}, True{}, False{}, False{}, CW{t[U32.add(K.co.T.pc(), U32.shrn(ci, 3n))], res},
        bud, cp, tw, ea, eb, lf, path, m, cp2, tw2, ea2, sr.edge(eb, v), ci, 0)
    case _ 1n+fq SR5{} _ _ _ _ CW{r, +res}:
      # hc holds the corners' entry until its word is read
      (t, +v) = r
      sr.go(d, fq, SR6{}, True{}, True{}, False{}, False{}, CW{t[U32.add(K.co.T.pa(), U32.shrn(ea2, 3n))], res},
        bud, cp, tw, ea, eb, lf, path, m, cp2, tw2, ea2, eb2, K.co.nib(v, hc), 0)
    case _ 1n+fq SR6{} _ _ _ _ CW{r, +res}:
      (t, +v) = r
      sr.go(d, fq, SR7{}, True{}, True{}, False{}, False{}, CW{t[U32.add(K.co.T.pb(), U32.shrn(eb2, 3n))], res},
        bud, cp, tw, ea, eb, lf, path, m, cp2, tw2, ea2, eb2, hc, K.co.nib(v, ea2))
    case _ 1n+fq SR7{} _ _ _ _ CW{r, +res}:
      (t, +v) = r
      +h = sr.max3(hc, ha, K.co.nib(v, eb2))
      sr.go(d, fq, SDec{}, True{}, True{}, U32.is_ge(h, bud), U32.is_zero(h), CW{(t, 0), res},
        bud, cp, tw, ea, eb, lf, path, m, cp2, tw2, ea2, eb2, hc, ha)
    case _ 1n+fq SDec{} _ _ True{} _ CW{r, +res}:
      # cut: the next move
      +mn = U32.add(m, 1)
      sr.go(d, fq, STry{}, U32.is_lt(mn, 18), sr.allowed(mn, lf), False{}, False{}, CW{r, sr.count(res)},
        bud, cp, tw, ea, eb, lf, path, mn, 0, 0, 0, 0, 0, 0)
    case _ 1n+fq SDec{} _ _ False{} True{} CW{r, +res}:
      # solved: this is a shortest solution (the bound's first)
      sr.go(d, fq, STry{}, False{}, False{}, False{}, False{}, CW{r, sr.win(res, m <> path)},
        bud, cp, tw, ea, eb, lf, path, m, 0, 0, 0, 0, 0, 0)
    case 0n 1n+fq SDec{} _ _ False{} False{} CW{r, +res}:
      sr.out(CW{r, res})
    case 1n+dq 1n+fq SDec{} _ _ False{} False{} CW{r, +res}:
      # within the bound: below the child, then the next move here
      +f = sr.face(m)
      sr.go(d, fq, SBack{}, True{}, True{}, False{}, False{},
        CR{sr.go(dq, 255n, STry{}, True{}, sr.allowed(0, f), False{}, False{}, CW{r, sr.count(res)},
          U32.sub(bud, 1), cp2, tw2, ea2, eb2, f, m <> path, 0, 0, 0, 0, 0, 0, 0)},
        bud, cp, tw, ea, eb, lf, path, m, 0, 0, 0, 0, 0, 0)
    case _ 1n+fq SBack{} _ _ _ _ CR{r}:
      (t, +res) = r
      +mn = U32.add(m, 1)
      sr.go(d, fq, STry{}, Bool.and(U32.is_lt(mn, 18), Bool.not(sr.found(res))), sr.allowed(mn, lf), False{}, False{}, CW{(t, 0), res},
        bud, cp, tw, ea, eb, lf, path, mn, 0, 0, 0, 0, 0, 0)
    case _ 1n+fq _ _ _ _ _ _:
      sr.out(c)

# A search of depth d below a node (path its moves so far, last first; lf its last face)
def sr.below(+d: Nat, t: Array<U32>, +cp: U32, +tw: U32, +ea: U32, +eb: U32, +lf: U32, +path: List<&2, U32>) -> Array<U32> & Res:
  sr.go(d, 255n, STry{}, True{}, sr.allowed(0, lf), False{}, False{}, CW{(t, 0), Res{None{}, 0}},
    U32.from_nat(d), cp, tw, ea, eb, lf, path, 0, 0, 0, 0, 0, 0, 0)

# A node's distance bound: its three distances' maximum
def sr.h3(+eb: U32, +hc: U32, +ha: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (t, +v) = r
  (t, sr.max3(hc, ha, K.co.nib(v, eb)))

def sr.h2(+ea: U32, +eb: U32, +hc: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (t, +v) = r
  sr.h3(eb, hc, K.co.nib(v, ea), t[U32.add(K.co.T.pb(), U32.shrn(eb, 3n))])

def sr.h1(+ea: U32, +eb: U32, +ci: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (t, +v) = r
  sr.h2(ea, eb, K.co.nib(v, ci), t[U32.add(K.co.T.pa(), U32.shrn(ea, 3n))])

def sr.h(t: Array<U32>, +cp: U32, +tw: U32, +ea: U32, +eb: U32) -> Array<U32> & U32:
  +ci = U32.add(U32.mul(cp, 2187), tw)
  sr.h1(ea, eb, ci, t[U32.add(K.co.T.pc(), U32.shrn(ci, 3n))])
