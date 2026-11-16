import Base
import ./Cube.bend as C
import ./Guard.bend as Gd
import ./Scheme.bend as Sc

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

# The faces seen in photo k: in front, on top, at the right (U R F D L B are
# 0..5), for the page's picture of how to hold the cube
def ph.pose(+k: U32) -> List<&2, U32>:
  Maybe.default(&2, List<&2, U32>, List.get(&2, List<&2, U32>,
    [[2, 0, 1], [1, 0, 5], [5, 0, 4], [4, 0, 2], [0, 5, 1], [3, 2, 1]], U32.to_nat(k)), [])

# the face Cube.bend's layout has on top of face f in a photo: B over U, F
# over D, U over the rest
def ph.up(+f: U32) -> U32:
  Bool.pick(U32, U32.is_eq(f, 0), 5, Bool.pick(U32, U32.is_eq(f, 3), 2, 0))

# the corner piece (0..7) a pose sees at its top right front, its faces read
# clockwise from its U or D face as Cube.bend lists them; 8 if no piece (a
# pose no cube can be held in: a mirror image, or faces not side by side)
def ph.pose.corner(+p: List<&2, U32>) -> U32:
  +t = Gd.gd.get(p, 1)
  +r = Gd.gd.get(p, 2)
  +f = Gd.gd.get(p, 0)
  +ud = U32.add(Gd.gd.ud(t), U32.add(Gd.gd.ud(r), Gd.gd.ud(f)))
  +o = Bool.pick(U32, U32.is_eq(Gd.gd.ud(t), 1), 0, Bool.pick(U32, U32.is_eq(Gd.gd.ud(r), 1), 1, 2))
  +j = Gd.gd.cfind(8n, C.cube.corner.colors(), Gd.gd.slot(o, t, r, f),
    Gd.gd.slot(U32.mod(U32.add(o, 1), 3), t, r, f), Gd.gd.slot(U32.mod(U32.add(o, 2), 3), t, r, f), 0)
  Bool.pick(U32, U32.is_eq(ud, 1), j, 8)

# The photos, one a line
# ----------------------

# chars cs (the last first) before acc
def ph.str(cs: List<&2, Char>, acc: String) -> String:
  match cs:
    case Nil{}:
      acc
    case Con{c, t}:
      ph.str(t, SCon{c, acc})

# s's lines, after char c (nl: whether it is a line break) and the chars of
# the line so far in cur (the last first). A loop: String.split recurses once
# a char, and compiled to JS that ran past a browser's stack on six photos
# (23,333 chars), so the page read nothing and said nothing
def ph.lines.go(s: String, nl: Bool, +c: Char, cur: List<&2, Char>, acc: List<&2, String>) -> List<&2, String>:
  match s nl:
    case SNil{} True{}:
      List.reverse(&2, String, SNil{} <> ph.str(cur, SNil{}) <> acc)
    case SCon{+d, t} True{}:
      ph.lines.go(t, Char.is_eq(d, '\n'), d, Nil{}, ph.str(cur, SNil{}) <> acc)
    case SNil{} False{}:
      List.reverse(&2, String, ph.str(c <> cur, SNil{}) <> acc)
    case SCon{+d, t} False{}:
      ph.lines.go(t, Char.is_eq(d, '\n'), d, c <> cur, acc)

def ph.lines(s: String) -> List<&2, String>:
  match s:
    case SNil{}:
      [""]
    case SCon{+c, t}:
      ph.lines.go(t, Char.is_eq(c, '\n'), c, Nil{}, Nil{})

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

# A face photographed twice
# -------------------------

# How unlike two colours may be and still be one: a sticker in two photos in
# one light is far closer (noise, a little shade), two colours in one light
# far farther (the closest, a phone's red and orange under a lamp: 28,134)
def ph.near() -> U32:
  8000

def ph.same(+p: Px, +q: Px) -> Bool:
  U32.is_lt(ph.dist(p, q), ph.near())

def ph.first(+ps: List<&2, Px>) -> Px:
  match ps:
    case Con{+p, t}:
      p
    case Nil{}:
      Px{0, 0, 0}

# a photo's centre sticker, as photographed
def ph.centre(s: String) -> Px:
  ph.first(ph.pxs(List.drop(&2, U32, ph.cells(s), 12n)))

def ph.centres.of(photos: List<&2, String>) -> List<&2, Px>:
  match photos:
    case Nil{}:
      Nil{}
    case Con{p, t}:
      ph.centre(p) <> ph.centres.of(t)

# the first of ps (from i) the colour x is, or 6
def ph.find(ps: List<&2, Px>, +x: Px, +i: U32) -> U32:
  match ps:
    case Nil{}:
      6
    case Con{+p, t}:
      Bool.pick(U32, ph.same(p, x), i, ph.find(t, x, U32.add(i, 1)))

# Which of the photos before the last has a centre the colour of the last
# one's (the same face again: the cube was not turned), or 6 if none
def ph.twin.of(cs: List<&2, Px>) -> U32:
  match cs:
    case Nil{}:
      6
    case Con{+last, rest}:
      ph.find(List.reverse(&2, Px, rest), last, 0)

def ph.twin(photos: List<&2, String>) -> U32:
  ph.twin.of(List.reverse(&2, Px, ph.centres.of(photos)))

# A photo's 9 stickers as photographed: 27 numbers, r g b of each (cells
# row by row from the top left), for the page to show what the camera sees
def ph.shows(xs: List<&2, U32>) -> List<&2, String>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+x, t}:
      U32.show(x) <> ph.shows(t)

def ph.seen.cells(s: String) -> String:
  String.join(ph.shows(ph.cells(s)), " ")

# Which colours the cube has
# --------------------------
#
# Not every cube has the page's colours (Scheme.bend). Photo k shows face
# ph.order[k]'s centre, and a scheme says what colour that is. For each
# scheme, the centres are evened out to its colours as a camera sees them
# (sc.col.cam): each channel times the scheme's sum of it over the photos'
# (so a lamp's yellow, or a shade's blue, is taken out as a whole), then each
# is compared to its colour (ph.dist). The scheme it adds up least for is the
# one the cube looks like. Schemes of the same six colours on other faces
# (Standard, Japanese, Mirrored) are told apart that way in any light: a
# light moves all the centres alike. So the page asks only that, and only
# once four photos are in (the four sides: red and orange, a close pair, are
# both seen then).

# the colour face f has in faces fs, as a camera sees it
def ph.cam(+fs: List<&2, U32>, +f: U32) -> Px:
  +c = Sc.sc.col.cam(Sc.sc.get(fs, f))
  Px{Gd.gd.get(c, 0), Gd.gd.get(c, 1), Gd.gd.get(c, 2)}

# the colours photos ks (0..5, ph.order's) have in faces fs
def ph.refs(+fs: List<&2, U32>, ks: List<&2, U32>) -> List<&2, Px>:
  match ks:
    case Nil{}:
      Nil{}
    case Con{+k, t}:
      ph.cam(fs, Gd.gd.get(ph.order(), k)) <> ph.refs(fs, t)

# channel ch of p (0 red, 1 green, 2 blue)
def ph.ch(+p: Px, +ch: U32) -> U32:
  match p:
    case Px{+r, +g, +b}:
      Bool.pick(U32, U32.is_eq(ch, 0), r, Bool.pick(U32, U32.is_eq(ch, 1), g, b))

def ph.sum(ps: List<&2, Px>, +ch: U32) -> U32:
  match ps:
    case Nil{}:
      0
    case Con{+p, t}:
      U32.add(ph.ch(p, ch), ph.sum(t, ch))

# what to even channel ch by: the scheme's sum of it over the photos', in
# 256ths
def ph.gain(+rs: List<&2, Px>, +cs: List<&2, Px>, +ch: U32) -> U32:
  U32.div(U32.mul(ph.sum(rs, ch), 256), U32.max(ph.sum(cs, ch), 1))

def ph.even.ch(+v: U32, +g: U32) -> U32:
  U32.min(U32.div(U32.mul(v, g), 256), 255)

def ph.even(+p: Px, +gr: U32, +gg: U32, +gb: U32) -> Px:
  match p:
    case Px{+r, +g, +b}:
      Px{ph.even.ch(r, gr), ph.even.ch(g, gg), ph.even.ch(b, gb)}

def ph.unlike.go(cs: List<&2, Px>, +rs: List<&2, Px>, +gr: U32, +gg: U32, +gb: U32) -> U32:
  match cs:
    case Nil{}:
      0
    case Con{+c, t}:
      U32.add(ph.dist(ph.even(c, gr, gg, gb), ph.first(rs)), ph.unlike.go(t, List.drop(&2, Px, rs, 1n), gr, gg, gb))

# how unlike centres cs (of photos ks) are to faces fs's colours
def ph.unlike(+fs: List<&2, U32>, +ks: List<&2, U32>, +cs: List<&2, Px>) -> U32:
  +rs = ph.refs(fs, ks)
  ph.unlike.go(cs, rs, ph.gain(rs, cs, 0), ph.gain(rs, cs, 1), ph.gain(rs, cs, 2))

# How much more unlike the page's scheme, and every other layout, must be
# than the one asked of (a made-up camera's noise and each photo in its own
# shade, in four photos: no wrong one in 43,200 tries at 15,000)
def ph.fit.margin() -> U32:
  15000

# more than any unlike adds up to
def ph.fit.big() -> U32:
  4000000000

def ph.preset.faces(+i: U32) -> List<&2, U32>:
  Sc.sc.faces(Sc.sc.preset(Sc.sc.at(i)))

# of the presets (from i, n of them) with faces cur's colours moved round,
# the one the centres look most like, as unlike * 8 + i; b the best so far
def ph.fit.best(n: Nat, +i: U32, +cur: List<&2, U32>, +ks: List<&2, U32>, +cs: List<&2, Px>, +b: U32) -> U32:
  match n:
    case 0n:
      b
    case 1n+q:
      +fs = ph.preset.faces(i)
      +u = U32.add(U32.mul(U32.min(ph.unlike(fs, ks, cs), 50000000), 8), i)
      ph.fit.best(q, U32.add(i, 1), cur, ks, cs, Bool.pick(U32, Bool.and(Sc.sc.moved(fs, cur), U32.is_lt(u, b)), u, b))

# the least unlike of those (from i, n of them) laid out other than faces bf
def ph.fit.next(n: Nat, +i: U32, +cur: List<&2, U32>, +bf: List<&2, U32>, +ks: List<&2, U32>, +cs: List<&2, Px>, +b: U32) -> U32:
  match n:
    case 0n:
      b
    case 1n+q:
      +fs = ph.preset.faces(i)
      +u = ph.unlike(fs, ks, cs)
      +other = Bool.and(Sc.sc.moved(fs, cur), Bool.not(Sc.sc.same(fs, bf)))
      ph.fit.next(q, U32.add(i, 1), cur, bf, ks, cs, Bool.pick(U32, Bool.and(other, U32.is_lt(u, b)), u, b))

# The preset the centres cs of photos ks look like, when the page's scheme
# (faces cur) is another layout of the same colours: four photos or more, and
# the page's and every other layout far more unlike. Sc.sc.count() if none
def ph.fit.of(+cs: List<&2, Px>, +ks: List<&2, U32>, +cur: List<&2, U32>) -> U32:
  +big = ph.fit.big()
  +p = ph.fit.best(5n, 0, cur, ks, cs, big)
  +i = U32.mod(p, 8)
  +bu = U32.div(p, 8)
  +bf = ph.preset.faces(i)
  +mine = Sc.sc.same(cur, bf)
  +nu = ph.fit.next(5n, 0, cur, bf, ks, cs, Bool.pick(U32, mine, big, ph.unlike(cur, ks, cs)))
  +ok = Bool.and(Bool.and(U32.is_ge(Sc.sc.len(ks), 4), U32.is_lt(p, big)),
          Bool.and(Bool.not(mine), U32.is_ge(nu, U32.add(bu, ph.fit.margin()))))
  Bool.pick(U32, ok, i, Sc.sc.count())

# the same, of the photos ks themselves
def ph.fit(+ks: List<&2, U32>, photos: List<&2, String>, +cur: List<&2, U32>) -> U32:
  ph.fit.of(ph.centres.of(photos), ks, cur)

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

type Light is Data:
  Day{}
  Lamp{}
  Shade{}

def ph.light(l: Light) -> List<&2, U32>:
  match l:
    case Day{}:
      ph.light.day()
    case Lamp{}:
      ph.light.lamp()
    case Shade{}:
      ph.light.shade()

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

# colour k of palette pal as a camera sees it in light lt
def ph.seen(+pal: List<&2, U32>, +lt: List<&2, U32>, +k: U32) -> Px:
  ph.first(ph.pxs(ph.look([k], pal, lt)))

# the centres of photos ks of a cube in preset p's colours, as a phone's
# camera sees them in light l
def ph.fit.seen.go(+pal: List<&2, U32>, +lt: List<&2, U32>, ks: List<&2, U32>) -> List<&2, Px>:
  match ks:
    case Nil{}:
      Nil{}
    case Con{+k, t}:
      ph.seen(pal, lt, Gd.gd.get(ph.order(), k)) <> ph.fit.seen.go(pal, lt, t)

def ph.fit.seen(p: Sc.Preset, l: Light, ks: List<&2, U32>) -> List<&2, Px>:
  ph.fit.seen.go(Sc.sc.cam.pal(Sc.sc.faces(Sc.sc.preset(p))), ph.light(l), ks)

# what the page should be told of a cube of preset p's colours when it shows
# preset c's: nothing if they are laid out alike, or are not the same colours;
# else the first preset laid out as p
def ph.fit.want(+p: Sc.Preset, +c: Sc.Preset) -> U32:
  +fp = Sc.sc.faces(Sc.sc.preset(p))
  +fc = Sc.sc.faces(Sc.sc.preset(c))
  Bool.pick(U32, Bool.or(Sc.sc.same(fp, fc), Bool.not(Sc.sc.moved(fp, fc))), Sc.sc.count(), Sc.sc.first(fp))
