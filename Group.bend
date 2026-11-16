import Base
import ./Cube.bend as C

# The cube group's words, for LAWS.bend to talk about: the six faces and the
# three ways to turn one, a move as a face and a turn, and the numbers that
# every cube a scramble can make keeps (its total twist, total flip, and the
# parities of its two permutations).
#
# Every def is prefixed `gr.`.

type Face is Data:
  FU{}
  FR{}
  FF{}
  FD{}
  FL{}
  FB{}

# a quarter turn clockwise, a half turn, a quarter turn back
type Turn is Data:
  TQ{}
  TH{}
  TI{}

# Cube.bend's numbering: faces U R F D L B are 0..5
def gr.face(f: Face) -> U32:
  match f:
    case FU{}:
      0
    case FR{}:
      1
    case FF{}:
      2
    case FD{}:
      3
    case FL{}:
      4
    case FB{}:
      5

# how many quarter turns clockwise a turn is
def gr.quarters(t: Turn) -> U32:
  match t:
    case TQ{}:
      1
    case TH{}:
      2
    case TI{}:
      3

# the move's number, face * 3 + (quarters - 1), as Cube.bend has it
def gr.m(f: Face, t: Turn) -> U32:
  U32.add(U32.mul(gr.face(f), 3), U32.sub(gr.quarters(t), 1))

# the move as a cube (a group element)
def gr.mv(f: Face, t: Turn) -> C.Cube:
  C.cube.move(gr.m(f, t))

# the face's quarter turn
def gr.turn(f: Face) -> C.Cube:
  gr.mv(f, TQ{})

# the face across: U D, R L, F B
def gr.opp(f: Face) -> Face:
  match f:
    case FU{}:
      FD{}
    case FR{}:
      FL{}
    case FF{}:
      FB{}
    case FD{}:
      FU{}
    case FL{}:
      FR{}
    case FB{}:
      FF{}

# whether the face is the first of its pair (U, R, F)
def gr.first(f: Face) -> Bool:
  match f:
    case FU{}:
      True{}
    case FR{}:
      True{}
    case FF{}:
      True{}
    case FD{}:
      False{}
    case FL{}:
      False{}
    case FB{}:
      False{}

# the turn the other way
def gr.inv(t: Turn) -> Turn:
  match t:
    case TQ{}:
      TI{}
    case TH{}:
      TH{}
    case TI{}:
      TQ{}

# The invariants
# --------------

def gr.sum(xs: List<&2, U32>) -> U32:
  match xs:
    case Nil{}:
      0
    case Con{+x, t}:
      U32.add(x, gr.sum(t))

# how many of ys are below x
def gr.below(+x: U32, ys: List<&2, U32>) -> U32:
  match ys:
    case Nil{}:
      0
    case Con{+y, t}:
      U32.add(Bool.pick(U32, U32.is_lt(y, x), 1, 0), gr.below(x, t))

# a permutation's inversions (pairs out of order)
def gr.inversions(xs: List<&2, U32>) -> U32:
  match xs:
    case Nil{}:
      0
    case Con{+x, +t}:
      U32.add(gr.below(x, t), gr.inversions(t))

# a permutation's parity: 0 even, 1 odd
def gr.parity(xs: List<&2, U32>) -> U32:
  U32.mod(gr.inversions(xs), 2)

# the corners' twists, summed mod 3
def gr.twist(+c: C.Cube) -> U32:
  match c:
    case C.Cube{cp, co, ep, eo}:
      U32.mod(gr.sum(co), 3)

# the edges' flips, summed mod 2
def gr.flip(+c: C.Cube) -> U32:
  match c:
    case C.Cube{cp, co, ep, eo}:
      U32.mod(gr.sum(eo), 2)

def gr.cparity(+c: C.Cube) -> U32:
  match c:
    case C.Cube{cp, co, ep, eo}:
      gr.parity(cp)

def gr.eparity(+c: C.Cube) -> U32:
  match c:
    case C.Cube{cp, co, ep, eo}:
      gr.parity(ep)

# R U R' U', "the sexy move"
def gr.sexy() -> C.Cube:
  C.cube.apply([3, 0, 5, 2], C.cube.solved())

# R U
def gr.ru() -> C.Cube:
  C.cube.mul(C.cube.R(), C.cube.U())

# s, then c n times over (C.cube.pow(c, n) is gr.iter(n, c, solved): PROOF.bend)
def gr.iter(n: Nat, +c: C.Cube, +s: C.Cube) -> C.Cube:
  match n:
    case 0n:
      s
    case 1n+p:
      gr.iter(p, c, C.cube.mul(s, c))
