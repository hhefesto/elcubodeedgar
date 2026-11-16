import Base
import ./Cube.bend as C
import ./Group.bend as G

# A cube from its stickers' colours, and whether it is one a real cube can
# be: the guard every way of setting a cube goes through (the camera, the
# paint, the server's c=).
#
# The stickers: 54 colours, each a face's number (0..5, U R F D L B: the
# colour of that face's centre), in Cube.bend's sticker order (Kociemba's
# facelets: U1..U9 R1..R9 F1..F9 D1..D9 L1..L9 B1..B9). A real cube has:
#   9 stickers of each colour, and each centre its face's colour;
#   at each corner place, the three colours of one of the 8 corner pieces,
#   at each edge place, the two of one of the 12 edges, each piece once;
#   corner twists adding up to 0 (mod 3), edge flips to 0 (mod 2), and
#   its corners' permutation as even as its edges' (LAWS.bend: move_twist,
#   move_flip, move_parity: every move keeps all three).
# gd.check reads the cube (Kociemba's facelet-to-cubie reading: a corner's
# twist is where its U or D colour is; its other two colours, clockwise from
# there, say which piece it is) and says plainly what is wrong if it is not
# one: the first of the above that fails.
#
# Every def is prefixed `gd.`.

# What the stickers are: a cube, or why not
type Read is Data:
  Good{+c: C.Cube}
  Bad{+why: String}

def gd.ok(+r: Read) -> Bool:
  match r:
    case Good{c}:
      True{}
    case Bad{w}:
      False{}

def gd.why(+r: Read) -> String:
  match r:
    case Good{c}:
      ""
    case Bad{+w}:
      w

# Stickers
# --------

# xs[i], or 6 (no colour) past the end
def gd.get(+xs: List<&2, U32>, +i: U32) -> U32:
  Maybe.default(&2, U32, List.get(&2, U32, xs, U32.to_nat(i)), 6)

# where x is in xs (from i), 255 if nowhere
def gd.index(+x: U32, xs: List<&2, U32>, +i: U32) -> U32:
  match xs:
    case Nil{}:
      255
    case Con{+y, t}:
      Bool.pick(U32, U32.is_eq(x, y), i, gd.index(x, t, U32.add(i, 1)))

# the colour of the sticker with code k (Cube.bend's: kind * 64 + place * 4 + slot)
def gd.at(+cols: List<&2, U32>, +k: U32) -> U32:
  gd.get(cols, gd.index(k, C.cube.stickers(), 0))

def gd.of.go(+c: C.Cube, codes: List<&2, U32>) -> List<&2, U32>:
  match codes:
    case Nil{}:
      Nil{}
    case Con{+k, t}:
      C.cube.color(c, k) <> gd.of.go(c, t)

# a cube's stickers' colours
def gd.of(+c: C.Cube) -> List<&2, U32>:
  gd.of.go(c, C.cube.stickers())

def gd.cols.go(s: String) -> List<&2, U32>:
  match s:
    case SNil{}:
      Nil{}
    case SCon{+c, t}:
      C.cube.face.of(c) <> gd.cols.go(t)

# the colours of a facelet string, "UUUUUUUUURRR..." (6 for a letter not a face)
def gd.cols(s: String) -> List<&2, U32>:
  gd.cols.go(s)

def gd.letters(cols: List<&2, U32>) -> String:
  match cols:
    case Nil{}:
      SNil{}
    case Con{+k, t}:
      SCon{C.cube.letter(k), gd.letters(t)}

# Names, for what is wrong
# ------------------------

def gd.name(+k: U32) -> String:
  Maybe.default(&2, String, List.get(&2, String, ["white", "red", "green", "yellow", "orange", "blue"], U32.to_nat(k)), "no colour")

def gd.cplace(+p: U32) -> String:
  Maybe.default(&2, String, List.get(&2, String, ["up-right-front", "up-front-left", "up-left-back", "up-back-right",
    "down-front-right", "down-left-front", "down-back-left", "down-right-back"], U32.to_nat(p)), "?")

def gd.eplace(+p: U32) -> String:
  Maybe.default(&2, String, List.get(&2, String, ["up-right", "up-front", "up-left", "up-back", "down-right",
    "down-front", "down-left", "down-back", "front-right", "front-left", "back-left", "back-right"], U32.to_nat(p)), "?")

# corner piece j's colours, "white-red-green"; edge piece j's
def gd.cpiece(+j: U32) -> String:
  +cc = C.cube.corner.colors()
  +i = U32.mul(j, 3)
  gd.name(gd.get(cc, i)) ++ "-" ++ gd.name(gd.get(cc, U32.add(i, 1))) ++ "-" ++ gd.name(gd.get(cc, U32.add(i, 2)))

def gd.epiece(+j: U32) -> String:
  +ec = C.cube.edge.colors()
  +i = U32.mul(j, 2)
  gd.name(gd.get(ec, i)) ++ "-" ++ gd.name(gd.get(ec, U32.add(i, 1)))

# Pieces
# ------

# a place's piece and its twist (or flip); or no piece has its colours
type Pc is Data:
  Pc{+j: U32, +o: U32}
  PNo{}

def gd.pc(ok: Bool, +j: U32, +o: U32) -> Pc:
  match ok:
    case True{}:
      Pc{j, o}
    case False{}:
      PNo{}

# whether colour c is U's or D's
def gd.ud(+c: U32) -> U32:
  Bool.to_u32(Bool.or(U32.is_eq(c, 0), U32.is_eq(c, 3)))

# the corner piece (from j) whose colours from its U or D one round are u, a, b; 8 if none
def gd.cfind(n: Nat, cc: List<&2, U32>, +u: U32, +a: U32, +b: U32, +j: U32) -> U32:
  match n cc:
    case 1n+p Con{+x, Con{+y, Con{+z, t}}}:
      Bool.pick(U32, Bool.and(U32.is_eq(x, u), Bool.and(U32.is_eq(y, a), U32.is_eq(z, b))), j, gd.cfind(p, t, u, a, b, U32.add(j, 1)))
    case _ _:
      8

# the edge piece (from j) whose colours are x, y in that order; 12 if none
def gd.efind(n: Nat, ec: List<&2, U32>, +x: U32, +y: U32, +j: U32) -> U32:
  match n ec:
    case 1n+p Con{+a, Con{+b, t}}:
      Bool.pick(U32, Bool.and(U32.is_eq(a, x), U32.is_eq(b, y)), j, gd.efind(p, t, x, y, U32.add(j, 1)))
    case _ _:
      12

# s of slot k (0..2) of a corner whose slots show s0 s1 s2
def gd.slot(+k: U32, +s0: U32, +s1: U32, +s2: U32) -> U32:
  Bool.pick(U32, U32.is_eq(k, 0), s0, Bool.pick(U32, U32.is_eq(k, 1), s1, s2))

def gd.corner.go(+o: U32, +n: U32, +s0: U32, +s1: U32, +s2: U32) -> Pc:
  +j = gd.cfind(8n, C.cube.corner.colors(), gd.slot(o, s0, s1, s2),
    gd.slot(U32.mod(U32.add(o, 1), 3), s0, s1, s2), gd.slot(U32.mod(U32.add(o, 2), 3), s0, s1, s2), 0)
  gd.pc(Bool.and(U32.is_eq(n, 1), U32.is_lt(j, 8)), j, o)

# corner place p: its twist is the slot with its U or D colour (one, if it is a corner)
def gd.corner(+cols: List<&2, U32>, +p: U32) -> Pc:
  +k = U32.add(64, U32.mul(p, 4))
  +s0 = gd.at(cols, k)
  +s1 = gd.at(cols, U32.add(k, 1))
  +s2 = gd.at(cols, U32.add(k, 2))
  +o = Bool.pick(U32, U32.is_eq(gd.ud(s0), 1), 0, Bool.pick(U32, U32.is_eq(gd.ud(s1), 1), 1, 2))
  gd.corner.go(o, U32.add(gd.ud(s0), U32.add(gd.ud(s1), gd.ud(s2))), s0, s1, s2)

def gd.edge.go(+j0: U32, +j1: U32) -> Pc:
  Bool.pick(Pc, U32.is_lt(j0, 12), Pc{j0, 0}, gd.pc(U32.is_lt(j1, 12), j1, 1))

# edge place p: its piece, as it is (flip 0) or the other way round (1)
def gd.edge(+cols: List<&2, U32>, +p: U32) -> Pc:
  +k = U32.add(128, U32.mul(p, 4))
  +x = gd.at(cols, k)
  +y = gd.at(cols, U32.add(k, 1))
  +ec = C.cube.edge.colors()
  gd.edge.go(gd.efind(12n, ec, x, y, 0), gd.efind(12n, ec, y, x, 0))

def gd.corners.go(n: Nat, +cols: List<&2, U32>, +p: U32) -> List<&2, Pc>:
  match n:
    case 0n:
      Nil{}
    case 1n+q:
      gd.corner(cols, p) <> gd.corners.go(q, cols, U32.add(p, 1))

def gd.edges.go(n: Nat, +cols: List<&2, U32>, +p: U32) -> List<&2, Pc>:
  match n:
    case 0n:
      Nil{}
    case 1n+q:
      gd.edge(cols, p) <> gd.edges.go(q, cols, U32.add(p, 1))

# the first place (from p) with no piece; n if none
def gd.none(ps: List<&2, Pc>, +p: U32) -> U32:
  match ps:
    case Nil{}:
      p
    case Con{+x, t}:
      match x:
        case Pc{j, o}:
          gd.none(t, U32.add(p, 1))
        case PNo{}:
          p

def gd.js(ps: List<&2, Pc>) -> List<&2, U32>:
  match ps:
    case Nil{}:
      Nil{}
    case Con{+x, t}:
      match x:
        case Pc{+j, o}:
          j <> gd.js(t)
        case PNo{}:
          99 <> gd.js(t)

def gd.os(ps: List<&2, Pc>) -> List<&2, U32>:
  match ps:
    case Nil{}:
      Nil{}
    case Con{+x, t}:
      match x:
        case Pc{j, +o}:
          o <> gd.os(t)
        case PNo{}:
          0 <> gd.os(t)

# Counts
# ------

def gd.count(xs: List<&2, U32>, +k: U32) -> U32:
  match xs:
    case Nil{}:
      0
    case Con{+x, t}:
      U32.add(Bool.to_u32(U32.is_eq(x, k)), gd.count(t, k))

def gd.len(xs: List<&2, U32>) -> U32:
  match xs:
    case Nil{}:
      0
    case Con{x, t}:
      U32.add(gd.len(t), 1)

# the colours (from k, n of them) not on exactly 9 stickers: "white 10, yellow 8"
def gd.off(n: Nat, +cols: List<&2, U32>, +k: U32) -> List<&2, String>:
  match n:
    case 0n:
      Nil{}
    case 1n+q:
      +c = gd.count(cols, k)
      +rest = gd.off(q, cols, U32.add(k, 1))
      Bool.pick(List<&2, String>, U32.is_eq(c, 9), rest, (gd.name(k) ++ " " ++ U32.show(c)) <> rest)

# the centres (from face k, n of them) not their face's colour
def gd.centres(n: Nat, +cols: List<&2, U32>, +k: U32) -> U32:
  match n:
    case 0n:
      0
    case 1n+q:
      U32.add(Bool.to_u32(U32.is_ne(gd.get(cols, U32.add(U32.mul(k, 9), 4)), k)), gd.centres(q, cols, U32.add(k, 1)))

# the first piece (from j, n of them) on more than one place; n + j if none
def gd.twice(n: Nat, +js: List<&2, U32>, +j: U32) -> U32:
  match n:
    case 0n:
      j
    case 1n+q:
      Bool.pick(U32, U32.is_gt(gd.count(js, j), 1), j, gd.twice(q, js, U32.add(j, 1)))

# The checks, in turn
# -------------------

def gd.mk(+cs: List<&2, Pc>, +es: List<&2, Pc>) -> C.Cube:
  C.Cube{gd.js(cs), gd.os(cs), gd.js(es), gd.os(es)}

# 7: the corners' permutation as even as the edges'
def gd.c7(+c: C.Cube) -> Read:
  Bool.pick(Read, U32.is_eq(G.gr.cparity(c), G.gr.eparity(c)), Good{c},
    Bad{"Two pieces are swapped (two corners, or two edges): a real cube cannot be like that, so some stickers were read or painted wrong."})

# 6: edge flips adding up to 0
def gd.c6(+c: C.Cube) -> Read:
  Bool.pick(Read, U32.is_zero(G.gr.flip(c)), gd.c7(c),
    Bad{"An edge is flipped: its two stickers are the wrong way round for a real cube. Look for an edge whose colours should swap."})

# 5: corner twists adding up to 0
def gd.c5(+c: C.Cube) -> Read:
  Bool.pick(Read, U32.is_zero(G.gr.twist(c)), gd.c6(c),
    Bad{"A corner is twisted: its three stickers are turned round from how a real cube can be. Look for a corner whose colours should go round."})

# 4: each edge piece once
def gd.c4(+cs: List<&2, Pc>, +es: List<&2, Pc>) -> Read:
  +d = gd.twice(12n, gd.js(es), 0)
  Bool.pick(Read, U32.is_ge(d, 12), gd.c5(gd.mk(cs, es)),
    Bad{"Two edges are the same piece, the " ++ gd.epiece(d) ++ " one: one of them must be another piece."})

# 3: each edge place one of the edges
def gd.c3(+cs: List<&2, Pc>, +cols: List<&2, U32>) -> Read:
  +es = gd.edges.go(12n, cols, 0)
  +p = gd.none(es, 0)
  +k = U32.add(128, U32.mul(p, 4))
  Bool.pick(Read, U32.is_ge(p, 12), gd.c4(cs, es),
    Bad{"The " ++ gd.eplace(p) ++ " edge has stickers " ++ gd.name(gd.at(cols, k)) ++ " and " ++ gd.name(gd.at(cols, U32.add(k, 1)))
      ++ ": no edge has those colours."})

# 2: each corner piece once
def gd.c2(+cs: List<&2, Pc>, +cols: List<&2, U32>) -> Read:
  +d = gd.twice(8n, gd.js(cs), 0)
  Bool.pick(Read, U32.is_ge(d, 8), gd.c3(cs, cols),
    Bad{"Two corners are the same piece, the " ++ gd.cpiece(d) ++ " one: one of them must be another piece."})

# 1: each corner place one of the corners
def gd.c1(+cols: List<&2, U32>) -> Read:
  +cs = gd.corners.go(8n, cols, 0)
  +p = gd.none(cs, 0)
  +k = U32.add(64, U32.mul(p, 4))
  Bool.pick(Read, U32.is_ge(p, 8), gd.c2(cs, cols),
    Bad{"The " ++ gd.cplace(p) ++ " corner has stickers " ++ gd.name(gd.at(cols, k)) ++ ", " ++ gd.name(gd.at(cols, U32.add(k, 1)))
      ++ " and " ++ gd.name(gd.at(cols, U32.add(k, 2))) ++ ": no corner has those colours."})

def gd.c0(+cols: List<&2, U32>, off: List<&2, String>) -> Read:
  match off:
    case Nil{}:
      Bool.pick(Read, U32.is_zero(gd.centres(6n, cols, 0)), gd.c1(cols),
        Bad{"A centre is not its own face's colour: the centres must be white, red, green, yellow, orange, blue for up, right, front, down, left, back."})
    case Con{x, t}:
      Bad{"Each colour must be on exactly 9 stickers, but: " ++ String.join(Con{x, t}, ", ") ++ "."}

# The stickers' colours: a real cube, or what is wrong (the first that is)
def gd.check(+cols: List<&2, U32>) -> Read:
  Bool.pick(Read, U32.is_eq(gd.len(cols), 54), gd.c0(cols, gd.off(6n, cols, 0)),
    Bad{"A cube has 54 stickers; these are " ++ U32.show(gd.len(cols)) ++ "."})

# The same, from a facelet string ("UUUUUUUUURRR...")
def gd.read(s: String) -> Read:
  gd.check(gd.cols(s))

# For the laws: cubes a real cube cannot be
# -----------------------------------------

type Cn is Data:
  CURF{}
  CUFL{}
  CULB{}
  CUBR{}
  CDFR{}
  CDLF{}
  CDBL{}
  CDRB{}

type Ed is Data:
  EUR{}
  EUF{}
  EUL{}
  EUB{}
  EDR{}
  EDF{}
  EDL{}
  EDB{}
  EFR{}
  EFL{}
  EBL{}
  EBR{}

def gd.cn(c: Cn) -> U32:
  match c:
    case CURF{}:
      0
    case CUFL{}:
      1
    case CULB{}:
      2
    case CUBR{}:
      3
    case CDFR{}:
      4
    case CDLF{}:
      5
    case CDBL{}:
      6
    case CDRB{}:
      7

def gd.ed(e: Ed) -> U32:
  match e:
    case EUR{}:
      0
    case EUF{}:
      1
    case EUL{}:
      2
    case EUB{}:
      3
    case EDR{}:
      4
    case EDF{}:
      5
    case EDL{}:
      6
    case EDB{}:
      7
    case EFR{}:
      8
    case EFL{}:
      9
    case EBL{}:
      10
    case EBR{}:
      11

def gd.zeros(n: Nat) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+q:
      0 <> gd.zeros(q)

def gd.upto(n: Nat, +i: U32) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+q:
      i <> gd.upto(q, U32.add(i, 1))

# 0 .. n - 1 with a and b swapped
def gd.swap.go(xs: List<&2, U32>, +a: U32, +b: U32) -> List<&2, U32>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+x, t}:
      Bool.pick(U32, U32.is_eq(x, a), b, Bool.pick(U32, U32.is_eq(x, b), a, x)) <> gd.swap.go(t, a, b)

# the solved cube with corner p twisted once clockwise
def gd.twisted(c: Cn) -> C.Cube:
  C.Cube{gd.upto(8n, 0), List.set(&2, U32, gd.zeros(8n), U32.to_nat(gd.cn(c)), 1), gd.upto(12n, 0), gd.zeros(12n)}

# the solved cube with edge e flipped
def gd.flipped(e: Ed) -> C.Cube:
  C.Cube{gd.upto(8n, 0), gd.zeros(8n), gd.upto(12n, 0), List.set(&2, U32, gd.zeros(12n), U32.to_nat(gd.ed(e)), 1)}

# the solved cube with corner p and the next one swapped
def gd.cswapped(c: Cn) -> C.Cube:
  +p = gd.cn(c)
  C.Cube{gd.swap.go(gd.upto(8n, 0), p, U32.mod(U32.add(p, 1), 8)), gd.zeros(8n), gd.upto(12n, 0), gd.zeros(12n)}

# the solved cube with edge e and the next one swapped
def gd.eswapped(e: Ed) -> C.Cube:
  +p = gd.ed(e)
  C.Cube{gd.upto(8n, 0), gd.zeros(8n), gd.swap.go(gd.upto(12n, 0), p, U32.mod(U32.add(p, 1), 12)), gd.zeros(12n)}

# the solved cube's stickers with face f's first painted the next face's colour
def gd.painted(+f: G.Face) -> List<&2, U32>:
  List.set(&2, U32, gd.of(C.cube.solved()), U32.to_nat(U32.mul(G.gr.face(f), 9)), U32.mod(U32.add(G.gr.face(f), 1), 6))
