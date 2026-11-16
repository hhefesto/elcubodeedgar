import Base
import ./Cube.bend as C
import ./Search.bend as S
import ./Group.bend as G
import ./Guard.bend as Gd

# The group theory the solver stands on, as laws. PROOF.bend proves each one;
# `bend PROOF.bend` prints ALL PROOFS CHECK only when every law holds.
#
# The moves generate a group (Cube.bend: a cube is a group element, mul is
# "this, then that", solved is the identity). The search (Search.bend) never
# tries two turns of one face in a row, and tries a face and the face across
# from it in one order only (U then D, never D then U). The laws below are why
# that loses no shortest solution, and that the search does just that.

# Each face's turns: a cyclic group of order 4
# --------------------------------------------

# a quarter turn four times is no turn
law quarter_turn_order:
  for f: G.Face
  {C.cube.pow(G.gr.turn(f), 4n) == C.cube.solved() : C.Cube}

# every move, then the same face the other way, is no move
law move_then_inverse:
  for f: G.Face
  for t: G.Turn
  {C.cube.mul(G.gr.mv(f, t), G.gr.mv(f, G.gr.inv(t))) == C.cube.solved() : C.Cube}

# two turns of a face in a row are one turn of it, or none: their quarter
# turns add, mod 4 (so a shortest solution never turns a face twice in a row)
law same_face_merge:
  for f: G.Face
  for t: G.Turn
  for u: G.Turn
  {C.cube.mul(G.gr.mv(f, t), G.gr.mv(f, u))
     == C.cube.pow(G.gr.turn(f), U32.to_nat(U32.mod(U32.add(G.gr.quarters(t), G.gr.quarters(u)), 4))) : C.Cube}

# Faces across from each other commute; others do not
# ---------------------------------------------------

# a turn of a face and a turn of the face across, in either order, are the
# same (so a search may try them in one order only)
law opposite_commute:
  for f: G.Face
  for t: G.Turn
  for u: G.Turn
  {C.cube.mul(G.gr.mv(f, t), G.gr.mv(G.gr.opp(f), u))
     == C.cube.mul(G.gr.mv(G.gr.opp(f), u), G.gr.mv(f, t)) : C.Cube}

# but the group is not commutative: R U is not U R
law not_abelian:
  {C.cube.eq(C.cube.mul(C.cube.R(), C.cube.U()), C.cube.mul(C.cube.U(), C.cube.R())) == False{} : Bool}

# What every move keeps
# ---------------------

# a move twists the corners by 0 in all (mod 3)
law move_twist:
  for f: G.Face
  for t: G.Turn
  {G.gr.twist(G.gr.mv(f, t)) == 0 : U32}

# a move flips the edges by 0 in all (mod 2)
law move_flip:
  for f: G.Face
  for t: G.Turn
  {G.gr.flip(G.gr.mv(f, t)) == 0 : U32}

# a move permutes the corners and the edges with the same parity
law move_parity:
  for f: G.Face
  for t: G.Turn
  {G.gr.cparity(G.gr.mv(f, t)) == G.gr.eparity(G.gr.mv(f, t)) : U32}

# Orders of famous elements
# -------------------------

# R U R' U' six times is nothing
law sexy_order:
  {C.cube.pow(G.gr.sexy(), 6n) == C.cube.solved() : C.Cube}

# R U, 105 times, is nothing
law ru_order:
  {C.cube.pow(G.gr.ru(), 105n) == C.cube.solved() : C.Cube}

# The search prunes by these
# --------------------------

# its face of a move (m * 11 >> 5) is the move's face
law search_face:
  for f: G.Face
  for t: G.Turn
  {S.sr.face(G.gr.m(f, t)) == G.gr.face(f) : U32}

# it never turns the face it just turned
law search_not_same_face:
  for f: G.Face
  for t: G.Turn
  {S.sr.allowed(G.gr.m(f, t), G.gr.face(f)) == False{} : Bool}

# after a face, it turns the face across only if that one comes later
# (U then D, never D then U)
law search_one_order:
  for f: G.Face
  for t: G.Turn
  {S.sr.allowed(G.gr.m(f, t), G.gr.face(G.gr.opp(f))) == Bool.not(G.gr.first(f)) : Bool}

# and before any move (6: no turn yet) it may begin with any move (until
# 11-15 it could not begin with D: 6 is D + 3)
law search_first:
  for f: G.Face
  for t: G.Turn
  {S.sr.allowed(G.gr.m(f, t), 6) == True{} : Bool}

# Reading a cube from its stickers (Guard.bend)
# ---------------------------------------------
#
# The camera, the paint and the server all set a cube by its stickers'
# colours, through Guard.bend's gd.check: the cube those stickers are, or why
# a real cube cannot have them.

# the solved cube's stickers read back as the solved cube
law read_solved:
  {Gd.gd.check(Gd.gd.of(C.cube.solved())) == Gd.Good{C.cube.solved()} : Gd.Read}

# every move's stickers read back as that move
law read_move:
  for f: G.Face
  for t: G.Turn
  {Gd.gd.check(Gd.gd.of(G.gr.mv(f, t))) == Gd.Good{G.gr.mv(f, t)} : Gd.Read}

# the superflip's (every edge flipped in place: what U R2 F B R B2 R U2 L B2
# R U' D' R2 F R' L B2 U2 F2 makes) read back as it
law read_superflip:
  {Gd.gd.check(Gd.gd.of(C.Cube{[0, 1, 2, 3, 4, 5, 6, 7], [0, 0, 0, 0, 0, 0, 0, 0], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]}))
     == Gd.Good{C.Cube{[0, 1, 2, 3, 4, 5, 6, 7], [0, 0, 0, 0, 0, 0, 0, 0], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]}} : Gd.Read}

# and a scrambled cube's, every piece moved and most turned (what the hand
# scramble L U' B2 U L F2 D' F2 R2 U B2 U' R F' R F' D L B' F2 R2 L' B makes)
law read_hand23:
  {Gd.gd.check(Gd.gd.of(C.Cube{[3, 2, 4, 5, 0, 6, 7, 1], [1, 0, 1, 1, 2, 0, 0, 1], [4, 1, 9, 8, 5, 6, 0, 2, 3, 7, 11, 10], [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0]}))
     == Gd.Good{C.Cube{[3, 2, 4, 5, 0, 6, 7, 1], [1, 0, 1, 1, 2, 0, 0, 1], [4, 1, 9, 8, 5, 6, 0, 2, 3, 7, 11, 10], [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0]}} : Gd.Read}

# a single corner twisted in place is refused, at every corner
law refuse_twisted:
  for p: Gd.Cn
  {Gd.gd.ok(Gd.gd.check(Gd.gd.of(Gd.gd.twisted(p)))) == False{} : Bool}

# a single edge flipped in place is refused, at every edge
law refuse_flipped:
  for e: Gd.Ed
  {Gd.gd.ok(Gd.gd.check(Gd.gd.of(Gd.gd.flipped(e)))) == False{} : Bool}

# two corners swapped (each and the next) are refused
law refuse_corners_swapped:
  for p: Gd.Cn
  {Gd.gd.ok(Gd.gd.check(Gd.gd.of(Gd.gd.cswapped(p)))) == False{} : Bool}

# two edges swapped (each and the next) are refused
law refuse_edges_swapped:
  for e: Gd.Ed
  {Gd.gd.ok(Gd.gd.check(Gd.gd.of(Gd.gd.eswapped(e)))) == False{} : Bool}

# a sticker painted another face's colour (10 of one, 8 of another) is refused
law refuse_painted:
  for f: G.Face
  {Gd.gd.ok(Gd.gd.check(Gd.gd.painted(f))) == False{} : Bool}
