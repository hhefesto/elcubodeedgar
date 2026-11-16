import Base

# Your cube's colors: which color each face of a real cube has, its color
# scheme. Cubes differ. Most have the standard one (white opposite yellow,
# green opposite blue, red opposite orange), but some have blue and yellow
# swapped (the Japanese scheme), some are the standard one's mirror image, and
# the shades differ (stickers, bright stickerless plastic, Rubik's Speed's
# coral red and sky blue, pastels with pink for red). The page only ever
# turns faces U R F D L B (Cube.bend): a scheme is how it shows them, and
# what it calls them.
#
# A color is a number: 0 white, 1 yellow, 2 red, 3 orange, 4 green, 5 blue,
# 6 pink, 7 purple, 8 black, 9 grey. A scheme's faces are the colors of
# U R F D L B, in that order, and its shades how the page paints them (r, g,
# b of each, 0..255).
#
# The page names a scheme with a key: a preset's number ("0" .. "5"), or six
# digits, a color for each face, for a scheme of the visitor's own. What it
# gets back is plain text.
#
# The page's messages (Guard.bend's, Photo.bend's) name faces by the standard
# scheme's colors ("the white centre on top"); sc.say puts the visitor's
# colors in their place (LAWS.bend: scheme_say_standard, scheme_say_face).
#
# Every def is prefixed `sc.`.

def sc.get(+xs: List<&2, U32>, +i: U32) -> U32:
  Maybe.default(&2, U32, List.get(&2, U32, xs, U32.to_nat(i)), 0)

def sc.len(xs: List<&2, U32>) -> U32:
  U32.from_nat(List.length(&2, U32, xs))

# The colors
# -----------

def sc.col.names() -> List<&2, String>:
  ["white", "yellow", "red", "orange", "green", "blue", "pink", "purple", "black", "grey"]

def sc.col.count() -> U32:
  10

def sc.col.name(+c: U32) -> String:
  Maybe.default(&2, String, List.get(&2, String, sc.col.names(), U32.to_nat(c)), "no color")

# a color as stickers have it: the shade the page paints a color of a
# scheme of the visitor's own
def sc.col.rgb(+c: U32) -> List<&2, U32>:
  Maybe.default(&2, List<&2, U32>, List.get(&2, List<&2, U32>,
    [[244, 240, 230], [255, 211, 26], [196, 18, 48], [255, 106, 19], [0, 160, 78], [11, 79, 179],
     [242, 107, 166], [123, 75, 179], [38, 34, 30], [143, 138, 131]], U32.to_nat(c)), [0, 0, 0])

# a color as a phone's camera saw a real cube's (Photo.bend's ph.pal.phone,
# for the first six; pink, purple, black and grey made like them)
def sc.col.cam(+c: U32) -> List<&2, U32>:
  Maybe.default(&2, List<&2, U32>, List.get(&2, List<&2, U32>,
    [[186, 192, 196], [206, 198, 44], [168, 32, 42], [226, 98, 34], [22, 148, 72], [24, 62, 150],
     [214, 92, 140], [96, 62, 140], [40, 40, 44], [120, 122, 126]], U32.to_nat(c)), [0, 0, 0])

# faces fs's colors as a camera sees them, r g b of each (the form of
# Photo.bend's palettes)
def sc.cam.pal(fs: List<&2, U32>) -> List<&2, U32>:
  match fs:
    case Nil{}:
      Nil{}
    case Con{+c, t}:
      List.append(&2, U32, sc.col.cam(c), sc.cam.pal(t))

# Schemes
# -------

type Scheme is Data:
  Scheme{+name: String, +about: String, +faces: List<&2, U32>, +shades: List<&2, U32>}

# the presets: the cubes most people have
type Preset is Data:
  Standard{}
  Stickerless{}
  Japanese{}
  Mirrored{}
  Pastel{}
  RubiksSpeed{}

def sc.preset(p: Preset) -> Scheme:
  match p:
    case Standard{}:
      Scheme{"Standard", "White opposite yellow, green opposite blue, red opposite orange: Rubik's own, and most cubes with stickers.",
        [0, 2, 4, 1, 3, 5], [244, 240, 230, 196, 18, 48, 0, 160, 78, 255, 211, 26, 255, 106, 19, 11, 79, 179]}
    case Stickerless{}:
      Scheme{"Bright stickerless", "The standard layout in bright plastic, as most speedcubes come: a vivid red, green and blue.",
        [0, 2, 4, 1, 3, 5], [250, 250, 247, 237, 28, 52, 38, 201, 76, 255, 236, 0, 255, 138, 0, 18, 128, 255]}
    case Japanese{}:
      Scheme{"Japanese", "Blue opposite white, yellow opposite green: the standard one with blue and yellow swapped.",
        [0, 2, 4, 5, 3, 1], [244, 240, 230, 196, 18, 48, 0, 160, 78, 11, 79, 179, 255, 106, 19, 255, 211, 26]}
    case Mirrored{}:
      Scheme{"Mirrored", "The standard one in a mirror: with white on top and green in front, orange is on the right and red on the left.",
        [0, 3, 4, 1, 2, 5], [244, 240, 230, 255, 106, 19, 0, 160, 78, 255, 211, 26, 196, 18, 48, 11, 79, 179]}
    case Pastel{}:
      Scheme{"Pastel", "Soft shades on the standard layout, pink in place of red.",
        [0, 6, 4, 1, 3, 5], [251, 248, 242, 245, 154, 184, 143, 217, 168, 251, 228, 138, 248, 178, 124, 138, 184, 240]}
    case RubiksSpeed{}:
      Scheme{"Rubik's Speed", "Rubik's own speedcube: the standard layout in its stickerless plastic, a coral red, a bright green and a sky blue.",
        [0, 2, 4, 1, 3, 5], [237, 238, 242, 242, 80, 94, 40, 205, 70, 252, 211, 4, 253, 145, 80, 10, 145, 212]}

def sc.count() -> U32:
  6

# preset i (Standard if none)
def sc.at(+i: U32) -> Preset:
  Bool.pick(Preset, U32.is_eq(i, 1), Stickerless{},
    Bool.pick(Preset, U32.is_eq(i, 2), Japanese{},
      Bool.pick(Preset, U32.is_eq(i, 3), Mirrored{},
        Bool.pick(Preset, U32.is_eq(i, 4), Pastel{},
          Bool.pick(Preset, U32.is_eq(i, 5), RubiksSpeed{}, Standard{})))))

def sc.index(p: Preset) -> U32:
  match p:
    case Standard{}:
      0
    case Stickerless{}:
      1
    case Japanese{}:
      2
    case Mirrored{}:
      3
    case Pastel{}:
      4
    case RubiksSpeed{}:
      5

# each color's sticker shade, in turn
def sc.shades(fs: List<&2, U32>) -> List<&2, U32>:
  match fs:
    case Nil{}:
      Nil{}
    case Con{+c, t}:
      List.append(&2, U32, sc.col.rgb(c), sc.shades(t))

# a scheme of the visitor's own: faces fs, each its color's sticker shade
def sc.own(+fs: List<&2, U32>) -> Scheme:
  Scheme{"Your own", "Each face the color you picked.", fs, sc.shades(fs)}

def sc.name(+s: Scheme) -> String:
  match s:
    case Scheme{+n, a, f, r}:
      n

def sc.about(+s: Scheme) -> String:
  match s:
    case Scheme{n, +a, f, r}:
      a

def sc.faces(+s: Scheme) -> List<&2, U32>:
  match s:
    case Scheme{n, a, +f, r}:
      f

def sc.rgb(+s: Scheme) -> List<&2, U32>:
  match s:
    case Scheme{n, a, f, +r}:
      r

# Keys
# ----

# the digits of s (a char that is no digit is 0)
def sc.digits(s: String) -> List<&2, U32>:
  match s:
    case SNil{}:
      Nil{}
    case SCon{+c, t}:
      Bool.pick(U32, Char.is_digit(c), U32.sub(Char.to_u32(c), 48), 0) <> sc.digits(t)

# the scheme a key names: six digits are the visitor's own, else a preset
def sc.of.ds(+ds: List<&2, U32>) -> Scheme:
  Bool.pick(Scheme, U32.is_eq(sc.len(ds), 6), sc.own(ds), sc.preset(sc.at(sc.get(ds, 0))))

def sc.of(+key: String) -> Scheme:
  sc.of.ds(sc.digits(key))

# What is wrong with faces fs as a cube's colors, or "" if nothing: six of
# them, each a color, no two the same
# ------------------------------------------------------------------------

def sc.has(fs: List<&2, U32>, +c: U32) -> U32:
  match fs:
    case Nil{}:
      0
    case Con{+x, t}:
      U32.add(Bool.to_u32(U32.is_eq(x, c)), sc.has(t, c))

# the first color (from c, n of them) on two faces or more; 10 if none
def sc.twice(n: Nat, +fs: List<&2, U32>, +c: U32) -> U32:
  match n:
    case 0n:
      sc.col.count()
    case 1n+q:
      Bool.pick(U32, U32.is_gt(sc.has(fs, c), 1), c, sc.twice(q, fs, U32.add(c, 1)))

def sc.why.faces(+fs: List<&2, U32>) -> String:
  +d = sc.twice(10n, fs, 0)
  Bool.pick(String, U32.is_ne(sc.len(fs), 6), "A cube has six faces: pick a color for each.",
    Bool.pick(String, U32.is_lt(d, sc.col.count()), "Two faces are " ++ sc.col.name(d) ++ ": each face needs a color of its own.", ""))

# Comparing schemes
# -----------------

# the same color on every face
def sc.same(a: List<&2, U32>, +b: List<&2, U32>) -> Bool:
  match a:
    case Nil{}:
      List.is_empty(&2, U32, b)
    case Con{+x, t}:
      Bool.and(U32.is_eq(x, sc.get(b, 0)), sc.same(t, List.drop(&2, U32, b, 1n)))

# the same colors, maybe on other faces: each of a's is one of b's (six
# different each, so one is the other's colors moved round)
def sc.moved(a: List<&2, U32>, +b: List<&2, U32>) -> Bool:
  match a:
    case Nil{}:
      True{}
    case Con{+x, t}:
      Bool.and(U32.is_gt(sc.has(b, x), 0), sc.moved(t, b))

# the first preset (from i, n of them) whose faces are fs; sc.count() if none
def sc.first.go(n: Nat, +fs: List<&2, U32>, +i: U32) -> U32:
  match n:
    case 0n:
      sc.count()
    case 1n+q:
      Bool.pick(U32, sc.same(sc.faces(sc.preset(sc.at(i))), fs), i, sc.first.go(q, fs, U32.add(i, 1)))

def sc.first(+fs: List<&2, U32>) -> U32:
  sc.first.go(5n, fs, 0)

# What the page is told
# ---------------------

def sc.name.of(+key: String) -> String:
  sc.name(sc.of(key))

def sc.about.of(+key: String) -> String:
  sc.about(sc.of(key))

def sc.shows(xs: List<&2, U32>) -> List<&2, String>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+x, t}:
      U32.show(x) <> sc.shows(t)

def sc.names(fs: List<&2, U32>) -> List<&2, String>:
  match fs:
    case Nil{}:
      Nil{}
    case Con{+c, t}:
      sc.col.name(c) <> sc.names(t)

# the faces' colors, U R F D L B, as digits: the key of the same scheme as
# one of the visitor's own
def sc.faces.of(+key: String) -> String:
  String.join(sc.shows(sc.faces(sc.of(key))), "")

# the faces' color names, U R F D L B, a space between
def sc.names.of(+key: String) -> String:
  String.join(sc.names(sc.faces(sc.of(key))), " ")

# shade k of rs (r, g, b each) as CSS: "rgb(244,240,230)"
def sc.css(+rs: List<&2, U32>, +k: U32) -> String:
  +i = U32.mul(k, 3)
  "rgb(" ++ U32.show(sc.get(rs, i)) ++ "," ++ U32.show(sc.get(rs, U32.add(i, 1))) ++ "," ++ U32.show(sc.get(rs, U32.add(i, 2))) ++ ")"

# what to write on shade k: dark ink ("d") on a light color, light ("l") on
# a dark one (its brightness, as eyes see it, 0..255: below 125 is dark)
def sc.ink(+rs: List<&2, U32>, +k: U32) -> String:
  +i = U32.mul(k, 3)
  +y = U32.div(U32.add(U32.add(U32.mul(sc.get(rs, i), 54), U32.mul(sc.get(rs, U32.add(i, 1)), 183)), U32.mul(sc.get(rs, U32.add(i, 2)), 19)), 256)
  Bool.pick(String, U32.is_lt(y, 125), "l", "d")

def sc.each(n: Nat, +rs: List<&2, U32>, +ink: Bool, +k: U32) -> List<&2, String>:
  match n:
    case 0n:
      Nil{}
    case 1n+q:
      Bool.pick(String, ink, sc.ink(rs, k), sc.css(rs, k)) <> sc.each(q, rs, ink, U32.add(k, 1))

# the faces' shades as CSS colors, U R F D L B, a space between
def sc.css.of(+key: String) -> String:
  String.join(sc.each(6n, sc.rgb(sc.of(key)), False{}, 0), " ")

# the ink for each face's color, "d" or "l", a space between
def sc.inks.of(+key: String) -> String:
  String.join(sc.each(6n, sc.rgb(sc.of(key)), True{}, 0), " ")

# what is wrong with a key's scheme, or "" (a preset: nothing)
def sc.why(+key: String) -> String:
  sc.why.faces(sc.faces(sc.of(key)))

# Picking a face's color
# -----------------------
#
# The visitor makes a scheme of their own a face at a time. A color another
# face has goes there in a swap (that face gets this one's old color), so the
# six stay six different colors (LAWS.bend: scheme_pick_*); and six that are
# a preset's are that preset, by its name.

def sc.pick.go(fs: List<&2, U32>, +i: U32, +f: U32, +c: U32, +old: U32) -> List<&2, U32>:
  match fs:
    case Nil{}:
      Nil{}
    case Con{+x, t}:
      Bool.pick(U32, U32.is_eq(i, f), c, Bool.pick(U32, U32.is_eq(x, c), old, x)) <> sc.pick.go(t, U32.add(i, 1), f, c, old)

# the key of key's scheme with face f (U R F D L B are 0..5) color c
def sc.pick(+key: String, +f: U32, +c: U32) -> String:
  +fs = sc.faces(sc.of(key))
  +ns = sc.pick.go(fs, 0, f, c, sc.get(fs, f))
  +p = sc.first(ns)
  Bool.pick(String, U32.is_lt(p, sc.count()), U32.show(p), String.join(sc.shows(ns), ""))

# the colors a scheme of the visitor's own may use, a space between, and
# their shades as CSS
def sc.palette() -> String:
  String.join(sc.col.names(), " ")

def sc.palette.css() -> String:
  String.join(sc.each(10n, sc.shades([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]), False{}, 0), " ")

# Saying it in the visitor's colors
# ----------------------------------

# the standard scheme's names, U R F D L B: the page's words for faces
def sc.std.names() -> List<&2, String>:
  ["white", "red", "green", "yellow", "orange", "blue"]

# the face (from f) whose standard name is w, or 6
def sc.std.face(ns: List<&2, String>, +w: String, +f: U32) -> U32:
  match ns:
    case Nil{}:
      6
    case Con{+n, t}:
      Bool.pick(U32, String.eq(n, w), f, sc.std.face(t, w, U32.add(f, 1)))

# a word as scheme faces fs says it: a face's standard name becomes the name
# of that face's color in fs
def sc.word(+fs: List<&2, U32>, +w: String) -> String:
  +f = sc.std.face(sc.std.names(), w, 0)
  Bool.pick(String, U32.is_lt(f, 6), sc.col.name(sc.get(fs, f)), w)

# chars cs (the last first) before acc
def sc.str(cs: List<&2, Char>, acc: String) -> String:
  match cs:
    case Nil{}:
      acc
    case Con{c, t}:
      sc.str(t, SCon{c, acc})

# s's chars onto out (the last first)
def sc.put(s: String, out: List<&2, Char>) -> List<&2, Char>:
  match s:
    case SNil{}:
      out
    case SCon{c, t}:
      sc.put(t, c <> out)

# the word so far (w, the last char first) said, onto out
def sc.flush(+fs: List<&2, U32>, w: List<&2, Char>, out: List<&2, Char>) -> List<&2, Char>:
  sc.put(sc.word(fs, sc.str(w, SNil{})), out)

# s said in faces fs's colors, a loop: the word so far in w, what is said
# so far in out (both the last char first)
def sc.say.go(s: String, +fs: List<&2, U32>, +w: List<&2, Char>, +out: List<&2, Char>) -> String:
  match s:
    case SNil{}:
      sc.str(sc.flush(fs, w, out), SNil{})
    case SCon{+c, t}:
      +a = Char.is_alpha(c)
      sc.say.go(t, fs, Bool.pick(List<&2, Char>, a, c <> w, Nil{}),
        Bool.pick(List<&2, Char>, a, out, c <> sc.flush(fs, w, out)))

def sc.say.in(+s: Scheme, msg: String) -> String:
  sc.say.go(msg, sc.faces(s), Nil{}, Nil{})

# a message in a key's scheme's colors
def sc.say(+key: String, msg: String) -> String:
  sc.say.in(sc.of(key), msg)
