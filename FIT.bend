# Laws BendTT's kernel runs out of fuel on, with their proofs: Photo.bend's
# ph.fit (which color scheme a cube's photos look like), the camera reading a
# scrambled cube, and "Enter your own cube" on a 23-move scramble. Bend's
# checker evaluates them (`bend FIT.bend --check-only`: ALL PROOFS CHECK, the
# flake's check "fit"); BendTT's kernel says "out of fuel" (--verdict, in
# scheme_fit_six, photo_reads_hand23, own_undo_hand23), so they are not in
# LAWS.bend, whose laws PROOF.bend's --verdict checks. A weaker warrant: the
# checker's evaluation, not the kernel's.
import Base
import ./Cube.bend as C
import ./Group.bend as G
import ./Guard.bend as Gd
import ./Photo.bend as Ph
import ./Scheme.bend as Sc
import ./Dev.bend as Dv

# The camera reads a cube: the stickers of a cube scrambled by hand (LAWS.bend's
# read_hand23, every piece moved), as a phone sees them in each light (no
# noise), are each given back their own color (ph.classify: the color of the
# centre each looks most like, the closest pairs first)
def Laws.h23() -> C.Cube:
  C.Cube{[3, 2, 4, 5, 0, 6, 7, 1], [1, 0, 1, 1, 2, 0, 0, 1], [4, 1, 9, 8, 5, 6, 0, 2, 3, 7, 11, 10], [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0]}

law Laws.photo_reads_hand23:
  for l: Ph.Light
  {Ph.ph.classify(Ph.ph.look(Gd.gd.of(Laws.h23()), Ph.ph.pal.phone(), Ph.ph.light(l))) == Gd.gd.of(Laws.h23()) : List<&2, U32>}

def Laws.photo_reads_hand23(l):
  match l:
    case Ph.Day{}:
      {==}
    case Ph.Lamp{}:
      {==}
    case Ph.Shade{}:
      {==}

# "Enter your own cube" (LAWS.bend's own_undo_move, own_undo_seq): the way
# back the solver finds solves the cube the page shows from it, for the hand
# scramble's 23 moves (L U' B2 U L F2 D' F2 R2 U B2 U' R F' R F' D L B' F2 R2
# L' B)
def Laws.h23.moves() -> List<&2, U32>:
  [12, 2, 16, 0, 12, 7, 11, 7, 4, 0, 16, 2, 3, 8, 3, 8, 9, 12, 17, 7, 4, 14, 15]

def Laws.undone(ms: List<&2, U32>) -> C.Cube:
  C.cube.apply(Maybe.default(&2, List<&2, U32>, C.cube.read(Dv.dv.undo(C.cube.nums(ms))), [0]), C.cube.solved())

law Laws.own_undo_hand23:
  {C.cube.apply(Laws.h23.moves(), Laws.undone(Laws.h23.moves())) == C.cube.solved() : C.Cube}

def Laws.own_undo_hand23():
  {==}

# The photos tell layouts apart: the centres of a cube in preset p's colors,
# as a phone sees them in each light, while the page shows preset c's, of the
# same colors moved round: the page is told p's layout exactly when c's is
# another, after the six photos, and after the first four (the sides)
law Laws.scheme_fit_six:
  for p: Sc.Preset
  for c: Sc.Preset
  for l: Ph.Light
  {Bool.or(Bool.not(Sc.sc.moved(Sc.sc.faces(Sc.sc.preset(p)), Sc.sc.faces(Sc.sc.preset(c)))),
     U32.is_eq(Ph.ph.fit.of(Ph.ph.fit.seen(p, l, [0, 1, 2, 3, 4, 5]), [0, 1, 2, 3, 4, 5], Sc.sc.faces(Sc.sc.preset(c))), Ph.ph.fit.want(p, c)))
     == True{} : Bool}

law Laws.scheme_fit_four:
  for p: Sc.Preset
  for c: Sc.Preset
  for l: Ph.Light
  {Bool.or(Bool.not(Sc.sc.moved(Sc.sc.faces(Sc.sc.preset(p)), Sc.sc.faces(Sc.sc.preset(c)))),
     U32.is_eq(Ph.ph.fit.of(Ph.ph.fit.seen(p, l, [0, 1, 2, 3]), [0, 1, 2, 3], Sc.sc.faces(Sc.sc.preset(c))), Ph.ph.fit.want(p, c)))
     == True{} : Bool}

# and never on fewer: three photos tell nothing
law Laws.scheme_fit_three:
  for p: Sc.Preset
  for c: Sc.Preset
  for l: Ph.Light
  {Ph.ph.fit.of(Ph.ph.fit.seen(p, l, [0, 1, 2]), [0, 1, 2], Sc.sc.faces(Sc.sc.preset(c))) == Sc.sc.count() : U32}

def Laws.scheme_fit_six(p, c, l):
  match p c l:
    case Sc.Standard{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.Standard{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.Standard{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.Standard{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.Standard{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.Standard{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}

def Laws.scheme_fit_four(p, c, l):
  match p c l:
    case Sc.Standard{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.Standard{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.Standard{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.Standard{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.Standard{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.Standard{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}

def Laws.scheme_fit_three(p, c, l):
  match p c l:
    case Sc.Standard{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.Standard{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.Standard{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.Standard{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.Standard{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.Standard{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.Standard{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.Standard{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.Stickerless{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.Stickerless{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.Stickerless{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.Japanese{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.Japanese{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.Japanese{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.Mirrored{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.Mirrored{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.Mirrored{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.Pastel{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.Pastel{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.Pastel{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Standard{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Standard{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Standard{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Stickerless{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Stickerless{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Stickerless{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Japanese{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Japanese{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Japanese{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Mirrored{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Mirrored{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Mirrored{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Pastel{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Pastel{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.Pastel{} Ph.Shade{}:
      {==}
    case Sc.RubiksSpeed{} Sc.RubiksSpeed{} Ph.Day{}:
      {==}
    case Sc.RubiksSpeed{} Sc.RubiksSpeed{} Ph.Lamp{}:
      {==}
    case Sc.RubiksSpeed{} Sc.RubiksSpeed{} Ph.Shade{}:
      {==}
