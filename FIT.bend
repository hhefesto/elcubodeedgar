# Laws of Photo.bend's ph.fit (which colour scheme a cube's photos look
# like), with their proofs. Bend's checker evaluates them (`bend FIT.bend
# --check-only`: ALL PROOFS CHECK, the flake's check "fit"); BendTT's kernel
# runs out of fuel on them (--verdict: "out of fuel" in scheme_fit_six), so
# they are not in LAWS.bend, whose laws PROOF.bend's --verdict checks.
import Base
import ./Cube.bend as C
import ./Group.bend as G
import ./Guard.bend as Gd
import ./Photo.bend as Ph
import ./Scheme.bend as Sc

# The photos tell layouts apart: the centres of a cube in preset p's colours,
# as a phone sees them in each light, while the page shows preset c's, of the
# same colours moved round: the page is told p's layout exactly when c's is
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
