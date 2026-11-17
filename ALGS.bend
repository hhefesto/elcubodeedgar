# Laws of "Solve it your way" (Ways.bend), with their proofs: the algorithms
# the ways use are read as their notation says, and each keeps what its step
# must keep. A step tries an algorithm only to reach its goal, and checks
# the goal (Ways.bend's wy.goal), so a wrong algorithm could only go unused;
# these laws say none is wrong, each by computation ({==}). Bend's checker
# evaluates them (`bend ALGS.bend --check-only`: ALL PROOFS CHECK, 5.5 min,
# the flake's check "algs"); BendTT's kernel says "out of fuel" (--verdict,
# in oll_keeps_f2l, the 57 OLL algorithms), as it does on FIT.bend's. A
# weaker warrant: the checker's evaluation, not the kernel's.
#
# What the laws do not say: that a way's moves solve every cube. Ways.bend
# searches, and a search is checked where it runs: Ways.bend checks each way
# solves its position, and the page checks it again (App.bend's wp.close,
# by Cube.bend) before it shows a move. probe/WaysT.bend runs 200 random
# scrambles (600 ways of 600 solve them); probe/ways.sh drives the page.
import Base
import ./Cube.bend as C
import ./Ways.bend as W

# Notation
# --------

# a wide turn is the face across turned the same way, with the cube (r = L x:
# after it, U is what was F); a middle slice is two faces, with the cube
# (M = R L' x', E = U D' y', S = F' B z); a turn of the cube turns no face
law Laws.algs_notation:
  {[W.wy.nt.ms("r"), W.wy.nt.ms("r U r'"), W.wy.nt.ms("M"), W.wy.nt.ms("E"), W.wy.nt.ms("S"), W.wy.nt.ms("x U"), W.wy.nt.ms("(R U) R2' R3")]
     == [[12], [12, 6, 14], [3, 14], [0, 11], [8, 15], [6], [3, 0, 4, 5]] : List<&2, List<&2, U32>>}

def Laws.algs_notation():
  {==}

# and an algorithm done from another side (Ways.bend's wy.sides, the cube
# turned as U turns it): R U R' U' from the right is B U B' U'
law Laws.algs_side:
  {W.wy.relabel(W.wy.nt.ms("R U R' U'"), W.wy.side(1)) == [15, 0, 17, 2] : List<&2, U32>}

def Laws.algs_side():
  {==}

# The last layer's algorithms (J Perm's)
# --------------------------------------

# every OLL algorithm reads, and done on a solved cube keeps the first two
# layers: so it changes the top only
law Laws.oll_keeps_f2l:
  {W.wy.keeps(W.wy.oll(), W.wy.k.f2l()) == True{} : Bool}

def Laws.oll_keeps_f2l():
  {==}

# every PLL algorithm keeps the first two layers, and the top's stickers up
law Laws.pll_keeps_oriented:
  {W.wy.keeps(W.wy.pll(), List.concat(&2, U32, [W.wy.k.f2l(), W.wy.k.eo(), W.wy.k.co()])) == True{} : Bool}

def Laws.pll_keeps_oriented():
  {==}

# the four looks: OLL's edges keep the first two layers; its corners those
# and the top's edges turned up; PLL's corners all that; its edges all that
# and the top's corners home
law Laws.oll2_keeps:
  {[W.wy.keeps(W.wy.oll2e(), W.wy.k.f2l()), W.wy.keeps(W.wy.oll2c(), W.wy.cat(W.wy.k.f2l(), W.wy.k.eo()))] == [True{}, True{}] : List<&2, Bool>}

def Laws.oll2_keeps():
  {==}

law Laws.pll2_keeps:
  {[W.wy.keeps(W.wy.pll2c(), List.concat(&2, U32, [W.wy.k.f2l(), W.wy.k.eo(), W.wy.k.co()])),
    W.wy.keeps(W.wy.pll2e(), List.concat(&2, U32, [W.wy.k.f2l(), W.wy.k.eo(), W.wy.k.co(), W.wy.k.lc()]))] == [True{}, True{}] : List<&2, Bool>}

def Laws.pll2_keeps():
  {==}

# The beginner's
# --------------

# R U R' U' keeps the cross; the middle edges' algorithms keep the bottom
# layer; the top's cross keeps the first two layers; its edges' algorithm
# those and the top's edges turned up; its corners' those and its edges home
law Laws.beginner_keeps:
  {[W.wy.keeps([W.Al{"", W.wy.b.corner()}], W.wy.k.cross()),
    W.wy.keeps(W.wy.b.edges(), W.wy.cat(W.wy.k.cross(), [4, 5, 6, 7])),
    W.wy.keeps(W.wy.b.cross(), W.wy.k.f2l()),
    W.wy.keeps(W.wy.b.tope(), W.wy.cat(W.wy.k.f2l(), W.wy.k.eo())),
    W.wy.keeps(W.wy.b.topc(), List.concat(&2, U32, [W.wy.k.f2l(), W.wy.k.eo(), W.wy.k.le()]))]
     == [True{}, True{}, True{}, True{}, True{}] : List<&2, Bool>}

def Laws.beginner_keeps():
  {==}

# R' D' R D six times is no move: so the last step's twists (two or four of
# them per corner, a multiple of six in all, as a cube's twists add up to
# none) leave the bottom layers as they were
law Laws.beginner_twist_six:
  {C.cube.apply(W.wy.rep(6n, W.wy.nt.ms("R' D' R D")), C.cube.solved()) == C.cube.solved() : C.Cube}

def Laws.beginner_twist_six():
  {==}

# and twice turns the front-right top corner one way, four times the other
law Laws.beginner_twist_turns:
  {[W.wy.co0(C.cube.apply(W.wy.rep(2n, W.wy.nt.ms("R' D' R D")), C.cube.solved())),
    W.wy.co0(C.cube.apply(W.wy.rep(4n, W.wy.nt.ms("R' D' R D")), C.cube.solved()))] == [2, 1] : List<&2, U32>}

def Laws.beginner_twist_turns():
  {==}
