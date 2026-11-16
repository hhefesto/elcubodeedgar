import Base
import ./Cube.bend as C
import ./Guard.bend as Gd

# A cube from six photos of it, one a face: the camera's half of "Read my
# cube" (the page's host only shows the camera and hands over the pixels).
#
# A photo: the square the page asks the face to fill, as 36 x 36 pixels, row
# by row from the top left, each pixel's red, green and blue as one char each
# (code 256 + value, so no char is a control or a surrogate): 3,888 chars.
# The square is 3 x 3 cells of 12 x 12 pixels, a sticker each; a sticker's
# colour is the median, channel by channel, of its cell's middle 6 x 6
# pixels (so a cube up to 3 pixels off, a sticker's black edge, or glare on
# a few pixels change nothing).
#
# The six photos are asked for in a fixed order, each with how to hold the
# cube (ph.hold), so that every photo is its face as Cube.bend's facelets lay
# it out (U seen with B on top, D with F on top, the others with U on top):
# a cell's place in the photo is the facelet's place in its face.
#
# Each sticker is then given the colour of the centre it looks most like, of
# the six centres in the same photos (so the light, the camera, and the cube's
# own shades matter little): the closest pairs first, and no colour on more
# than 9 stickers. What that gives goes through Guard.bend like any cube.
#
# Every def is prefixed `ph.`.

# A sticker's colour as photographed: red, green, blue (0..255)
type Px is Data:
  Px{+r: U32, +g: U32, +b: U32}

# Holding the cube
# ----------------

# the photos' faces, in the order they are asked for: F R B L U D
def ph.order() -> List<&2, U32>:
  [2, 1, 5, 4, 0, 3]

# which photo face f (U R F D L B) is in
def ph.shot.of(+f: U32) -> U32:
  Gd.gd.get([4, 1, 0, 5, 3, 2], f)

# how to hold the cube for photo k
def ph.hold(+k: U32) -> String:
  Maybe.default(&2, String, List.get(&2, String,
    ["The green centre facing you, the white centre on top.",
     "The red centre facing you, the white centre on top (turn the cube a quarter to the left).",
     "The blue centre facing you, the white centre on top (another quarter to the left).",
     "The orange centre facing you, the white centre on top (another quarter to the left).",
     "The white centre facing you, the blue centre on top (green facing you again, then tip the top toward you).",
     "The yellow centre facing you, the green centre on top (green facing you again, then tip the bottom toward you)."],
    U32.to_nat(k)), "")

# Reading a photo
# ---------------

# the photo's side, in pixels; a cell's
def ph.side() -> U32:
  36

def ph.chars() -> U32:
  3888

# a char's channel value: its code less 256, within 0..255
def ph.val(+c: Char) -> U32:
  +k = Char.to_u32(c)
  Bool.pick(U32, U32.is_lt(k, 256), 0, U32.min(U32.sub(k, 256), 255))

# whether offset o (0..35) is in its cell's middle 6 pixels
def ph.mid(+o: U32) -> Bool:
  +r = U32.mod(o, 12)
  Bool.and(U32.is_ge(r, 3), U32.is_lt(r, 9))

# Each middle pixel's channel, as one number: (cell * 3 + channel) * 256 + value
# (so sorting them sorts each cell's channel's values, the groups in order)
def ph.keys.go(s: String, +i: U32, +acc: List<&2, U32>) -> List<&2, U32>:
  match s:
    case SNil{}:
      acc
    case SCon{+c, t}:
      +p = U32.div(i, 3)
      +x = U32.mod(p, 36)
      +y = U32.div(p, 36)
      +ok = Bool.and(U32.is_lt(y, 36), Bool.and(ph.mid(x), ph.mid(y)))
      +g = U32.add(U32.mul(U32.add(U32.mul(U32.div(y, 12), 3), U32.div(x, 12)), 3), U32.mod(i, 3))
      ph.keys.go(t, U32.add(i, 1), Bool.pick(List<&2, U32>, ok, U32.add(U32.mul(g, 256), ph.val(c)) <> acc, acc))

# group g's values, of keys sorted (last first)
def ph.group(ks: List<&2, U32>, +g: U32, +acc: List<&2, U32>) -> List<&2, U32>:
  match ks:
    case Nil{}:
      acc
    case Con{+k, t}:
      ph.group(t, g, Bool.pick(List<&2, U32>, U32.is_eq(U32.shrn(k, 8n), g), U32.and(k, 255) <> acc, acc))

# the middle one of xs (0 if none)
def ph.middle(+xs: List<&2, U32>) -> U32:
  Maybe.default(&2, U32, List.get(&2, U32, xs, Nat.div(List.length(&2, U32, xs), 2n)), 0)

def ph.meds.go(+ks: List<&2, U32>, n: Nat, +g: U32, +acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      List.reverse(&2, U32, acc)
    case 1n+p:
      ph.meds.go(ks, p, U32.add(g, 1), ph.middle(ph.group(ks, g, Nil{})) <> acc)

# A photo's 9 stickers' colours: each cell's median red, green, blue (27
# numbers, the cells row by row from the top left)
def ph.cells(s: String) -> List<&2, U32>:
  ph.meds.go(List.sort(~U32, ~U32.is_le, ph.keys.go(s, 0, Nil{})), 27n, 0, Nil{})

# Telling the colours apart
# -------------------------

# r g b numbers as colours
def ph.pxs(xs: List<&2, U32>) -> List<&2, Px>:
  match xs:
    case +r <> +g <> +b <> t:
      Px{r, g, b} <> ph.pxs(t)
    case _:
      Nil{}

def ph.sq(+a: U32, +b: U32) -> U32:
  +d = Bool.pick(U32, U32.is_lt(a, b), U32.sub(b, a), U32.sub(a, b))
  U32.mul(d, d)

# How unlike two colours are: their red, green and blue shares of their
# brightness (in thousandths) apart, squared, and a little of their
# brightness apart (so a face in shade is still its colour)
def ph.dist(+p: Px, +q: Px) -> U32:
  match p q:
    case Px{+r1, +g1, +b1} Px{+r2, +g2, +b2}:
      +s1 = U32.add(U32.add(U32.add(r1, g1), b1), 1)
      +s2 = U32.add(U32.add(U32.add(r2, g2), b2), 1)
      U32.add(U32.add(ph.sq(U32.div(U32.mul(r1, 1000), s1), U32.div(U32.mul(r2, 1000), s2)),
                      ph.sq(U32.div(U32.mul(g1, 1000), s1), U32.div(U32.mul(g2, 1000), s2))),
              U32.add(ph.sq(U32.div(U32.mul(b1, 1000), s1), U32.div(U32.mul(b2, 1000), s2)),
                      U32.div(ph.sq(U32.div(s1, 3), U32.div(s2, 3)), 4)))

# the stickers at the centres (4, 13, .., 49)
def ph.centres(ps: List<&2, Px>, +i: U32, +acc: List<&2, Px>) -> List<&2, Px>:
  match ps:
    case Nil{}:
      List.reverse(&2, Px, acc)
    case Con{+p, t}:
      ph.centres(t, U32.add(i, 1), Bool.pick(List<&2, Px>, U32.is_eq(U32.mod(i, 9), 4), p <> acc, acc))

# sticker i's distance to each centre f, as one number: d * 512 + i * 8 + f
# (so sorting them puts the closest pairs first)
def ph.pairs.face(+p: Px, cs: List<&2, Px>, +i: U32, +f: U32, +acc: List<&2, U32>) -> List<&2, U32>:
  match cs:
    case Nil{}:
      acc
    case Con{+q, t}:
      ph.pairs.face(p, t, i, U32.add(f, 1),
        U32.add(U32.mul(U32.min(ph.dist(p, q), 8000000), 512), U32.add(U32.mul(i, 8), f)) <> acc)

def ph.pairs(ps: List<&2, Px>, +cs: List<&2, Px>, +i: U32, +acc: List<&2, U32>) -> List<&2, U32>:
  match ps:
    case Nil{}:
      acc
    case Con{+p, t}:
      ph.pairs(t, cs, U32.add(i, 1),
        Bool.pick(List<&2, U32>, U32.is_eq(U32.mod(i, 9), 4), acc, ph.pairs.face(p, cs, i, 0, acc)))

# no colour yet (6), but each centre its face's
def ph.blank(n: Nat, +i: U32, +acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      List.reverse(&2, U32, acc)
    case 1n+p:
      ph.blank(p, U32.add(i, 1), Bool.pick(U32, U32.is_eq(U32.mod(i, 9), 4), U32.div(i, 9), 6) <> acc)

# the pairs, closest first: sticker i gets colour f if it has none yet and f
# is on fewer than 9 (every sticker gets one: 6 colours of 9 are 54)
def ph.assign(ks: List<&2, U32>, +cols: List<&2, U32>, +cnt: List<&2, U32>) -> List<&2, U32>:
  match ks:
    case Nil{}:
      cols
    case Con{+k, t}:
      +i = U32.mod(U32.shrn(k, 3n), 64)
      +f = U32.mod(k, 8)
      +ok = Bool.and(U32.is_eq(Gd.gd.get(cols, i), 6), U32.is_lt(Gd.gd.get(cnt, f), 9))
      ph.assign(t, Bool.pick(List<&2, U32>, ok, List.set(&2, U32, cols, U32.to_nat(i), f), cols),
        Bool.pick(List<&2, U32>, ok, List.set(&2, U32, cnt, U32.to_nat(f), U32.add(Gd.gd.get(cnt, f), 1)), cnt))

# The stickers' colours (Guard.bend's: 54 of 0..5, facelet order) from their
# colours as photographed (162 numbers: r, g, b of each, facelet order)
def ph.classify(+meds: List<&2, U32>) -> List<&2, U32>:
  +ps = ph.pxs(meds)
  ph.assign(List.sort(~U32, ~U32.is_le, ph.pairs(ps, ph.centres(ps, 0, Nil{}), 0, Nil{})),
    ph.blank(54n, 0, Nil{}), [1, 1, 1, 1, 1, 1])

def ph.shot(+shots: List<&2, List<&2, U32>>, +f: U32) -> List<&2, U32>:
  Maybe.default(&2, List<&2, U32>, List.get(&2, List<&2, U32>, shots, U32.to_nat(ph.shot.of(f))), Nil{})

# the six photos' stickers (in the order taken: ph.order), in facelet order
def ph.meds(+shots: List<&2, List<&2, U32>>) -> List<&2, U32>:
  List.concat(&2, U32, [ph.shot(shots, 0), ph.shot(shots, 1), ph.shot(shots, 2), ph.shot(shots, 3), ph.shot(shots, 4), ph.shot(shots, 5)])

def ph.cells.all(photos: List<&2, String>) -> List<&2, List<&2, U32>>:
  match photos:
    case Nil{}:
      Nil{}
    case Con{p, t}:
      ph.cells(p) <> ph.cells.all(t)

# The cube in six photos (in the order taken), or what is wrong with it
def ph.read(+photos: List<&2, String>) -> Gd.Read:
  Gd.gd.check(ph.classify(ph.meds(ph.cells.all(photos))))

# Photos made up, for the tests and the laws
# ------------------------------------------

# Marsaglia's xorshift32
def ph.rand(+x: U32) -> U32:
  +a = U32.xor(x, U32.shln(x, 13n))
  +b = U32.xor(a, U32.shrn(a, 17n))
  U32.xor(b, U32.shln(b, 5n))

# sticker colours: the page's (Cube.bend's U R F D L B: white, red, green,
# yellow, orange, blue), and a real cube's as a phone saw them
def ph.pal.page() -> List<&2, U32>:
  [244, 240, 230, 196, 18, 48, 0, 160, 78, 255, 211, 26, 255, 106, 19, 11, 79, 179]

def ph.pal.phone() -> List<&2, U32>:
  [186, 192, 196, 168, 32, 42, 22, 148, 72, 206, 198, 44, 226, 98, 34, 24, 62, 150]

# lights: each channel times t / 256
def ph.light.day() -> List<&2, U32>:
  [256, 256, 256]

def ph.light.lamp() -> List<&2, U32>:
  [300, 246, 176]

def ph.light.shade() -> List<&2, U32>:
  [150, 160, 176]

# channel ch of the pixel at x, y of a photo of a face with colours cols, the
# cube sx, sy pixels down and right of where it should be, less 3 (0..6)
def ph.px(+cols: List<&2, U32>, +pal: List<&2, U32>, +lt: List<&2, U32>, +sx: U32, +sy: U32, +x: U32, +y: U32, +ch: U32) -> U32:
  +ok = Bool.and(Bool.and(U32.is_ge(U32.add(x, 3), sx), U32.is_ge(U32.add(y, 3), sy)),
                 Bool.and(U32.is_lt(U32.sub(U32.add(x, 3), sx), 36), U32.is_lt(U32.sub(U32.add(y, 3), sy), 36)))
  +xs = U32.sub(U32.add(x, 3), sx)
  +ys = U32.sub(U32.add(y, 3), sy)
  +ox = U32.mod(xs, 12)
  +oy = U32.mod(ys, 12)
  +inside = Bool.and(ok, Bool.and(Bool.and(U32.is_ge(ox, 1), U32.is_lt(ox, 11)), Bool.and(U32.is_ge(oy, 1), U32.is_lt(oy, 11))))
  +k = Gd.gd.get(cols, U32.add(U32.mul(U32.div(ys, 12), 3), U32.div(xs, 12)))
  +v = Bool.pick(U32, inside, Gd.gd.get(pal, U32.add(U32.mul(k, 3), ch)), 18)
  U32.min(U32.div(U32.mul(v, Gd.gd.get(lt, ch)), 256), 255)

# the value with noise: up to a either way, from h
def ph.noisy(+v: U32, +a: U32, +h: U32) -> U32:
  +w = U32.add(v, U32.mod(U32.shrn(h, 7n), U32.add(U32.mul(a, 2), 1)))
  U32.min(Bool.pick(U32, U32.is_lt(w, a), 0, U32.sub(w, a)), 255)

def ph.paint.go(n: Nat, +i: U32, +cols: List<&2, U32>, +pal: List<&2, U32>, +lt: List<&2, U32>, +sx: U32, +sy: U32, +a: U32, +seed: U32, +acc: String) -> String:
  match n:
    case 0n:
      acc
    case 1n+q:
      +p = U32.div(i, 3)
      +v = ph.noisy(ph.px(cols, pal, lt, sx, sy, U32.mod(p, 36), U32.div(p, 36), U32.mod(i, 3)), a,
             ph.rand(U32.xor(seed, U32.mul(U32.add(i, 1), 2654435761))))
      ph.paint.go(q, U32.sub(i, 1), cols, pal, lt, sx, sy, a, seed, SCon{Char.from_u32(U32.add(v, 256)), acc})

# A photo of a face with colours cols (its 9), as the page's host would hand
# it: in light lt, the cube sx, sy pixels off (3: none), with noise up to a
# either way (from seed)
def ph.paint(+cols: List<&2, U32>, +pal: List<&2, U32>, +lt: List<&2, U32>, +sx: U32, +sy: U32, +a: U32, +seed: U32) -> String:
  ph.paint.go(3888n, 3887, cols, pal, lt, sx, sy, a, seed, SNil{})

# face f's 9 of a cube's 54 colours
def ph.face(+cols: List<&2, U32>, +f: U32) -> List<&2, U32>:
  List.take(&2, U32, List.drop(&2, U32, cols, U32.to_nat(U32.mul(f, 9))), 9n)

# The six photos of stickers cols, in the order asked for: each off by up to
# 3 pixels either way, with noise up to 20 (from seed)
def ph.photos.go(n: Nat, +k: U32, +cols: List<&2, U32>, +pal: List<&2, U32>, +lt: List<&2, U32>, +seed: U32) -> List<&2, String>:
  match n:
    case 0n:
      Nil{}
    case 1n+q:
      +h = ph.rand(U32.add(seed, U32.mul(k, 40503)))
      ph.paint(ph.face(cols, Gd.gd.get(ph.order(), k)), pal, lt, U32.mod(h, 7), U32.mod(U32.shrn(h, 8n), 7), 20, h)
        <> ph.photos.go(q, U32.add(k, 1), cols, pal, lt, seed)

def ph.photos(+cols: List<&2, U32>, +pal: List<&2, U32>, +lt: List<&2, U32>, +seed: U32) -> List<&2, String>:
  ph.photos.go(6n, 0, cols, pal, lt, seed)

# The stickers' colours as a camera sees them, in light lt (r, g, b of each:
# what ph.cells finds in a photo without noise)
def ph.look(cols: List<&2, U32>, +pal: List<&2, U32>, +lt: List<&2, U32>) -> List<&2, U32>:
  match cols:
    case Nil{}:
      Nil{}
    case Con{+k, t}:
      +i = U32.mul(k, 3)
      U32.min(U32.div(U32.mul(Gd.gd.get(pal, i), Gd.gd.get(lt, 0)), 256), 255)
        <> U32.min(U32.div(U32.mul(Gd.gd.get(pal, U32.add(i, 1)), Gd.gd.get(lt, 1)), 256), 255)
        <> U32.min(U32.div(U32.mul(Gd.gd.get(pal, U32.add(i, 2)), Gd.gd.get(lt, 2)), 256), 255)
        <> ph.look(t, pal, lt)
