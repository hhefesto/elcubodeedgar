import Base
import ./Cube.bend as C
import ./Search.bend as S
import ./Group.bend as G
import ./Guard.bend as Gd
import ./Lite.bend as L
import ./Kd.bend as D
import ./Coord.bend as K
import ./Photo.bend as Ph
import ./Scheme.bend as Sc

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

# The shortest search's bound (Kd.bend)
# -------------------------------------
# Its table keeps each cube's distance to Lite.bend's phase-1 goal S mod 3
# (2 bits): the search knows its node's exact distance, and a move changes it
# by at most one.

# so a neighbour's residue gives its exact distance: one more, the same, or
# one less, for every distance the table holds (0 .. 12)
law fst_step:
  {D.kd.step.all(13n) == True{} : Bool}

# Kd.bend ranks the slice edges' places (a set of 4 of 12, a mask) by a sum
# of binomials, without Lite.bend's list of the 495: each by how many such
# masks are smaller, its place in that list. All 4,096 masks, 256 a law
# (one law for all of them runs out of the kernel's fuel)
law fst_rank_0:
  {D.kd.rank.from(256n, 0, 0) == True{} : Bool}

law fst_rank_1:
  {D.kd.rank.from(256n, 256, 70) == True{} : Bool}

law fst_rank_2:
  {D.kd.rank.from(256n, 512, 126) == True{} : Bool}

law fst_rank_3:
  {D.kd.rank.from(256n, 768, 182) == True{} : Bool}

law fst_rank_4:
  {D.kd.rank.from(256n, 1024, 210) == True{} : Bool}

law fst_rank_5:
  {D.kd.rank.from(256n, 1280, 266) == True{} : Bool}

law fst_rank_6:
  {D.kd.rank.from(256n, 1536, 294) == True{} : Bool}

law fst_rank_7:
  {D.kd.rank.from(256n, 1792, 322) == True{} : Bool}

law fst_rank_8:
  {D.kd.rank.from(256n, 2048, 330) == True{} : Bool}

law fst_rank_9:
  {D.kd.rank.from(256n, 2304, 386) == True{} : Bool}

law fst_rank_10:
  {D.kd.rank.from(256n, 2560, 414) == True{} : Bool}

law fst_rank_11:
  {D.kd.rank.from(256n, 2816, 442) == True{} : Bool}

law fst_rank_12:
  {D.kd.rank.from(256n, 3072, 450) == True{} : Bool}

law fst_rank_13:
  {D.kd.rank.from(256n, 3328, 478) == True{} : Bool}

law fst_rank_14:
  {D.kd.rank.from(256n, 3584, 486) == True{} : Bool}

law fst_rank_15:
  {D.kd.rank.from(256n, 3840, 494) == True{} : Bool}

# S's places (the slice edges home): the solved cube's slice edges sit at
# places 8 .. 11 (the mask 3840), and Kd ranks that set 494, the last of the
# 495. Lite's rank of it, its place in lt.masks(), is the same count (the
# fst_rank laws above); computing that list of 495 in the kernel runs out of
# fuel, so the law names the mask and the rank, not Lite's list
law fst_home_mask:
  {L.lt.mask(K.co.places([8, 9, 10, 11], L.lt.ep(C.cube.solved()))) == 3840 : U32}

law fst_home:
  {D.kd.home() == 494 : U32}

# Reading your cube from photos (Photo.bend)
# ------------------------------------------

# the page hands over the six photos one a line, and they come apart there
# again (ph.lines, a loop: String.split's recursion ran past the browser's
# stack, and the page read nothing)
law photo_lines:
  for a: G.Face
  for b: G.Face
  {Ph.ph.lines(Gd.gd.name(G.gr.face(a)) ++ "\n" ++ Gd.gd.name(G.gr.face(b)))
     == [Gd.gd.name(G.gr.face(a)), Gd.gd.name(G.gr.face(b))] : List<&2, String>}

law photo_lines_empty:
  {Ph.ph.lines("\nU\n\nR\n") == ["", "U", "", "R", ""] : List<&2, String>}

# the picture of how to hold the cube for a face's photo has that face in
# front, and on top the face Photo.bend's layout reads above it (B over U, F
# over D, U over the rest)
law photo_pose_front:
  for f: G.Face
  {Gd.gd.get(Ph.ph.pose(Ph.ph.shot.of(G.gr.face(f))), 0) == G.gr.face(f) : U32}

law photo_pose_top:
  for f: G.Face
  {Gd.gd.get(Ph.ph.pose(Ph.ph.shot.of(G.gr.face(f))), 1) == Ph.ph.up(G.gr.face(f)) : U32}

# and a cube can be held that way: its front, top and right faces meet at a
# corner piece, in the corner's own order (not a mirror image)
law photo_pose_corner:
  for f: G.Face
  {U32.is_lt(Ph.ph.pose.corner(Ph.ph.pose(Ph.ph.shot.of(G.gr.face(f)))), 8) == True{} : Bool}

# a face photographed twice is caught, and two faces never pass for one: in
# each light, each of a real cube's colours as a phone saw them (ph.pal.phone)
# is the same as itself and as no other (red and orange under a lamp too)
law photo_same_face:
  for a: G.Face
  for b: G.Face
  for l: Ph.Light
  {Ph.ph.same(Ph.ph.seen(Ph.ph.pal.phone(), Ph.ph.light(l), G.gr.face(a)),
              Ph.ph.seen(Ph.ph.pal.phone(), Ph.ph.light(l), G.gr.face(b)))
     == U32.is_eq(G.gr.face(a), G.gr.face(b)) : Bool}

# Your cube's colours (Scheme.bend)
# ---------------------------------

# every preset gives the six faces six different colours
law scheme_six:
  for p: Sc.Preset
  {Sc.sc.why.faces(Sc.sc.faces(Sc.sc.preset(p))) == "" : String}

# a preset's number names it (the page keeps the number)
law scheme_key:
  for p: Sc.Preset
  {Sc.sc.at(Sc.sc.index(p)) == p : Sc.Preset}

# and six digits are a scheme of the visitor's own, two faces of one colour
# caught
law scheme_own:
  {Sc.sc.why("022135") == "Two faces are red: each face needs a colour of its own." : String}

# the Japanese scheme is the standard one with yellow and blue swapped (down
# and back), the mirrored one with red and orange (right and left)
law scheme_japanese:
  {Sc.sc.faces(Sc.sc.preset(Sc.Japanese{}))
     == List.set(&2, U32, List.set(&2, U32, Sc.sc.faces(Sc.sc.preset(Sc.Standard{})), 3n, 5), 5n, 1) : List<&2, U32>}

law scheme_mirrored:
  {Sc.sc.faces(Sc.sc.preset(Sc.Mirrored{}))
     == List.set(&2, U32, List.set(&2, U32, Sc.sc.faces(Sc.sc.preset(Sc.Standard{})), 1n, 3), 4n, 2) : List<&2, U32>}

# the page's messages name faces by the standard scheme's colours: in the
# standard scheme they are said as they are
law scheme_say_standard:
  for a: G.Face
  for b: G.Face
  {Sc.sc.say("0", "The " ++ Gd.gd.name(G.gr.face(a)) ++ "-" ++ Gd.gd.name(G.gr.face(b)) ++ " edge (white 8).")
     == "The " ++ Gd.gd.name(G.gr.face(a)) ++ "-" ++ Gd.gd.name(G.gr.face(b)) ++ " edge (white 8)." : String}

# and in every preset, a face's standard name is said as its colour there
law scheme_say_face:
  for p: Sc.Preset
  for f: G.Face
  {Sc.sc.say.in(Sc.sc.preset(p), "the " ++ Gd.gd.name(G.gr.face(f)) ++ " centre")
     == "the " ++ Sc.sc.col.name(Sc.sc.get(Sc.sc.faces(Sc.sc.preset(p)), G.gr.face(f))) ++ " centre" : String}

# a face's colour picked (the picker's "None of these?"): a colour another
# face has swaps with it, so from every preset, whichever face is given
# whichever of the standard six, the six stay six different colours
law scheme_pick_six:
  for p: Sc.Preset
  for f: G.Face
  for g: G.Face
  {Sc.sc.why(Sc.sc.pick(U32.show(Sc.sc.index(p)), G.gr.face(f), Sc.sc.get(Sc.sc.faces(Sc.sc.preset(Sc.Standard{})), G.gr.face(g)))) == "" : String}

# and six that are a preset's are that preset: the standard one's bottom
# made blue is the Japanese one, its right made orange the mirrored one, and
# the Japanese one's bottom made yellow the standard one again
law scheme_pick_presets:
  {[Sc.sc.pick("0", 3, 5), Sc.sc.pick("0", 1, 3), Sc.sc.pick("2", 3, 1)] == ["2", "3", "0"] : List<&2, String>}
