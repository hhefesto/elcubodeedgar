import Base
import ./Cube.bend as C
import ./Search.bend as S
import ./Group.bend as G

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
