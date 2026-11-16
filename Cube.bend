import Base

# Rubik's cube, the cubie level (Kociemba's): what a state means.
#
# A state is where each piece is and how it is turned. Places and pieces are
# numbered alike: corners URF UFL ULB UBR DFR DLF DBL DRB (0..7), edges
# UR UF UL UB DR DF DL DB FR FL BL BR (0..11).
#   cp[i]: the corner at place i;  co[i]: its twist, 0..2
#   ep[i]: the edge at place i;    eo[i]: its flip, 0..1
# A state is also a group element: a * b is "a, then b", each place's piece
# looked up through b's places (Kociemba's multiplication):
#   (a * b).cp[i] = a.cp[b.cp[i]]     (a * b).co[i] = a.co[b.cp[i]] + b.co[i]  (mod 3)
# and the same for edges, mod 2. A move m on a state s is s * move(m).
#
# Moves are numbered face * 3 + k: faces U R F D L B (0..5), k 0 a quarter
# turn clockwise, 1 a half turn, 2 a quarter turn back (U, U2, U').
#
# Every def is prefixed `cube.` (a program's defs share one namespace).

type Cube is Data:
  Cube{+cp: List<&2, U32>, +co: List<&2, U32>, +ep: List<&2, U32>, +eo: List<&2, U32>}

# xs[i], or 0 past the end
def cube.at(+xs: List<&2, U32>, +i: U32) -> U32:
  Maybe.default(&2, U32, List.get(&2, U32, xs, U32.to_nat(i)), 0)

# (a * b)'s places from a's and b's: a's entry at each of b's
def cube.mul.p(+a: List<&2, U32>, b: List<&2, U32>) -> List<&2, U32>:
  match b:
    case Nil{}:
      Nil{}
    case Con{+j, t}:
      cube.at(a, j) <> cube.mul.p(a, t)

# (a * b)'s turns, mod k
def cube.mul.o(+ao: List<&2, U32>, bp: List<&2, U32>, bo: List<&2, U32>, +k: U32) -> List<&2, U32>:
  match bp bo:
    case Con{+j, t} Con{+o, u}:
      U32.mod(U32.add(cube.at(ao, j), o), k) <> cube.mul.o(ao, t, u, k)
    case _ _:
      Nil{}

def cube.mul(+a: Cube, +b: Cube) -> Cube:
  match a b:
    case Cube{acp, aco, aep, aeo} Cube{bcp, bco, bep, beo}:
      Cube{cube.mul.p(acp, bcp), cube.mul.o(aco, bcp, bco, 3), cube.mul.p(aep, bep), cube.mul.o(aeo, bep, beo, 2)}

def cube.solved() -> Cube:
  Cube{[0, 1, 2, 3, 4, 5, 6, 7], [0, 0, 0, 0, 0, 0, 0, 0],
       [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]}

# The six quarter turns, clockwise looking at the face (Kociemba's tables)
def cube.U() -> Cube:
  Cube{[3, 0, 1, 2, 4, 5, 6, 7], [0, 0, 0, 0, 0, 0, 0, 0],
       [3, 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]}

def cube.R() -> Cube:
  Cube{[4, 1, 2, 0, 7, 5, 6, 3], [2, 0, 0, 1, 1, 0, 0, 2],
       [8, 1, 2, 3, 11, 5, 6, 7, 4, 9, 10, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]}

def cube.F() -> Cube:
  Cube{[1, 5, 2, 3, 0, 4, 6, 7], [1, 2, 0, 0, 2, 1, 0, 0],
       [0, 9, 2, 3, 4, 8, 6, 7, 1, 5, 10, 11], [0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0]}

def cube.D() -> Cube:
  Cube{[0, 1, 2, 3, 5, 6, 7, 4], [0, 0, 0, 0, 0, 0, 0, 0],
       [0, 1, 2, 3, 5, 6, 7, 4, 8, 9, 10, 11], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]}

def cube.L() -> Cube:
  Cube{[0, 2, 6, 3, 4, 1, 5, 7], [0, 1, 2, 0, 0, 2, 1, 0],
       [0, 1, 10, 3, 4, 5, 9, 7, 8, 2, 6, 11], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]}

def cube.B() -> Cube:
  Cube{[0, 1, 3, 7, 4, 5, 2, 6], [0, 0, 1, 2, 0, 0, 2, 1],
       [0, 1, 2, 11, 4, 5, 6, 10, 8, 9, 3, 7], [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1]}

def cube.faces() -> List<&2, Cube>:
  [cube.U(), cube.R(), cube.F(), cube.D(), cube.L(), cube.B()]

# c to the n
def cube.pow(+c: Cube, n: Nat) -> Cube:
  match n:
    case 0n:
      cube.solved()
    case 1n+p:
      cube.mul(cube.pow(c, p), c)

# move m: face m / 3 turned (m % 3) + 1 quarter turns
def cube.move(+m: U32) -> Cube:
  +f = Maybe.default(&2, Cube, List.get(&2, Cube, cube.faces(), U32.to_nat(U32.div(m, 3))), cube.solved())
  cube.pow(f, U32.to_nat(U32.add(U32.mod(m, 3), 1)))

# the moves ms done on c, in order
def cube.apply(ms: List<&2, U32>, +c: Cube) -> Cube:
  match ms:
    case Nil{}:
      c
    case Con{+m, t}:
      cube.apply(t, cube.mul(c, cube.move(m)))

# The inverse of a move: the same face, the other way (a half turn is its own)
def cube.inv.move(+m: U32) -> U32:
  +k = U32.mod(m, 3)
  U32.add(U32.sub(m, k), U32.sub(2, k))

# The moves that undo ms: each undone, last first
def cube.inv.go(ms: List<&2, U32>, acc: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      acc
    case Con{+m, t}:
      cube.inv.go(t, cube.inv.move(m) <> acc)

def cube.inv(ms: List<&2, U32>) -> List<&2, U32>:
  cube.inv.go(ms, Nil{})

# Whether two lists of numbers are the same
def cube.list.eq(xs: List<&2, U32>, ys: List<&2, U32>) -> Bool:
  match xs ys:
    case Nil{} Nil{}:
      True{}
    case Con{+x, t} Con{+y, u}:
      Bool.and(U32.is_eq(x, y), cube.list.eq(t, u))
    case _ _:
      False{}

def cube.eq(+a: Cube, +b: Cube) -> Bool:
  match a b:
    case Cube{acp, aco, aep, aeo} Cube{bcp, bco, bep, beo}:
      Bool.and(Bool.and(cube.list.eq(acp, bcp), cube.list.eq(aco, bco)),
               Bool.and(cube.list.eq(aep, bep), cube.list.eq(aeo, beo)))

def cube.is_solved(+c: Cube) -> Bool:
  cube.eq(c, cube.solved())

# Notation
# --------

def cube.names() -> List<&2, String>:
  ["U", "U2", "U'", "R", "R2", "R'", "F", "F2", "F'", "D", "D2", "D'", "L", "L2", "L'", "B", "B2", "B'"]

def cube.name(+m: U32) -> String:
  Maybe.default(&2, String, List.get(&2, String, cube.names(), U32.to_nat(m)), "?")

def cube.show.go(ms: List<&2, U32>) -> List<&2, String>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+m, t}:
      cube.name(m) <> cube.show.go(t)

# "R U R' U'"
def cube.show(ms: List<&2, U32>) -> String:
  String.join(cube.show.go(ms), " ")

# A face's letter: 0..5, or 6 for none
def cube.face.pick(u: Bool, r: Bool, f: Bool, d: Bool, l: Bool, b: Bool) -> U32:
  match u r f d l b:
    case True{} _ _ _ _ _:
      0
    case False{} True{} _ _ _ _:
      1
    case False{} False{} True{} _ _ _:
      2
    case False{} False{} False{} True{} _ _:
      3
    case False{} False{} False{} False{} True{} _:
      4
    case False{} False{} False{} False{} False{} True{}:
      5
    case False{} False{} False{} False{} False{} False{}:
      6

def cube.face.of(+c: Char) -> U32:
  +d = Char.to_upper(c)
  cube.face.pick(Char.is_eq(d, 'U'), Char.is_eq(d, 'R'), Char.is_eq(d, 'F'),
                 Char.is_eq(d, 'D'), Char.is_eq(d, 'L'), Char.is_eq(d, 'B'))

# What follows the letter: nothing, 2 or ' (2' is 2 too); 3 for anything else
def cube.suf.pick(none: Bool, two: Bool, back: Bool, twob: Bool) -> U32:
  match none two back twob:
    case True{} _ _ _:
      0
    case False{} True{} _ _:
      1
    case False{} False{} True{} _:
      2
    case False{} False{} False{} True{}:
      1
    case False{} False{} False{} False{}:
      3

def cube.suf.of(+s: String) -> U32:
  cube.suf.pick(String.is_empty(s), String.eq(s, "2"), Bool.or(String.eq(s, "'"), String.eq(s, "’")), String.eq(s, "2'"))

def cube.tok.ok(ok: Bool, +m: U32) -> Maybe<&2, U32>:
  match ok:
    case True{}:
      Some{m}
    case False{}:
      None{}

def cube.tok.mk(+f: U32, +k: U32) -> Maybe<&2, U32>:
  cube.tok.ok(Bool.and(U32.is_lt(f, 6), U32.is_lt(k, 3)), U32.add(U32.mul(f, 3), k))

# One move, "R'", or None
def cube.tok(+s: String) -> Maybe<&2, U32>:
  match s:
    case SNil{}:
      None{}
    case SCon{+c, +rest}:
      cube.tok.mk(cube.face.of(c), cube.suf.of(rest))

def cube.parse.cons2(m: Maybe<&2, U32>, r: Maybe<&2, List<&2, U32>>) -> Maybe<&2, List<&2, U32>>:
  match m r:
    case Some{+x} Some{xs}:
      Some{x <> xs}
    case _ _:
      None{}

def cube.parse.cons(empty: Bool, +t: String, r: Maybe<&2, List<&2, U32>>) -> Maybe<&2, List<&2, U32>>:
  match empty:
    case True{}:
      r
    case False{}:
      cube.parse.cons2(cube.tok(t), r)

def cube.parse.go(ts: List<&2, String>) -> Maybe<&2, List<&2, U32>>:
  match ts:
    case Nil{}:
      Some{Nil{}}
    case Con{+t, rest}:
      cube.parse.cons(String.is_empty(t), t, cube.parse.go(rest))

# Spaces between moves; commas and new lines count as spaces
def cube.blank(+c: Char) -> Char:
  Bool.pick(Char, Bool.or(Char.is_space(c), Char.is_eq(c, ',')), ' ', c)

def cube.blanks(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{+c, t}:
      SCon{cube.blank(c), cube.blanks(t)}

# "R U R' U'" as moves, or None if a word is not a move
def cube.parse(s: String) -> Maybe<&2, List<&2, U32>>:
  cube.parse.go(String.split(cube.blanks(s), ' '))

# The stickers
# ------------

# Each of the 54 stickers, U1..U9 R1..R9 F1..F9 D1..D9 L1..L9 B1..B9 (each
# face read row by row as it is seen): kind * 64 + place * 4 + slot, kind 0 a
# center (place: its face), 1 a corner, 2 an edge; slot: which of the piece's
# stickers (Kociemba's cornerFacelet and edgeFacelet, slot 0 on U or D).
def cube.stickers() -> List<&2, U32>:
  [72, 140, 76, 136, 0, 128, 68, 132, 64,
   65, 129, 78, 161, 4, 173, 82, 145, 93,
   69, 133, 66, 164, 8, 160, 86, 149, 81,
   84, 148, 80, 152, 12, 144, 88, 156, 92,
   73, 137, 70, 169, 16, 165, 90, 153, 85,
   77, 141, 74, 172, 20, 168, 94, 157, 89]

# The colors of each corner's stickers and each edge's, slot by slot, as faces
def cube.corner.colors() -> List<&2, U32>:
  [0, 1, 2, 0, 2, 4, 0, 4, 5, 0, 5, 1, 3, 2, 1, 3, 4, 2, 3, 5, 4, 3, 1, 5]

def cube.edge.colors() -> List<&2, U32>:
  [0, 1, 0, 2, 0, 4, 0, 5, 3, 1, 3, 2, 3, 4, 3, 5, 2, 1, 2, 4, 5, 4, 5, 1]

# A sticker's color (its face, 0..5), from the code above
def cube.color.pick(+c: Cube, +place: U32, +slot: U32, corner: Bool, edge: Bool) -> U32:
  match c corner edge:
    case Cube{cp, co, ep, eo} True{} _:
      +n = U32.mod(U32.sub(U32.add(slot, 3), cube.at(co, place)), 3)
      cube.at(cube.corner.colors(), U32.add(U32.mul(cube.at(cp, place), 3), n))
    case Cube{cp, co, ep, eo} False{} True{}:
      +n = U32.xor(slot, cube.at(eo, place))
      cube.at(cube.edge.colors(), U32.add(U32.mul(cube.at(ep, place), 2), n))
    case Cube{cp, co, ep, eo} False{} False{}:
      place

def cube.color(+c: Cube, +code: U32) -> U32:
  +kind = U32.shrn(code, 6n)
  cube.color.pick(c, U32.and(U32.shrn(code, 2n), 15), U32.and(code, 3), U32.is_eq(kind, 1), U32.is_eq(kind, 2))

def cube.letter(+k: U32) -> Char:
  Maybe.default(&2, Char, String.get("URFDLB", U32.to_nat(k)), '?')

def cube.facelets.go(+c: Cube, codes: List<&2, U32>) -> String:
  match codes:
    case Nil{}:
      SNil{}
    case Con{+k, t}:
      SCon{cube.letter(cube.color(c, k)), cube.facelets.go(c, t)}

# The 54 stickers as their faces' letters, "UUUUUUUUURRR...": the facelet
# string Kociemba's programs read and write
def cube.facelets(+c: Cube) -> String:
  cube.facelets.go(c, cube.stickers())

# The wire form
# -------------

# Moves as numbers, "3.10.17", the form the server and the page trade them in
def cube.nums.go(ms: List<&2, U32>) -> List<&2, String>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+m, t}:
      U32.show(m) <> cube.nums.go(t)

def cube.nums(ms: List<&2, U32>) -> String:
  String.join(cube.nums.go(ms), ".")

def cube.read.cons(m: Maybe<&2, U32>, r: Maybe<&2, List<&2, U32>>) -> Maybe<&2, List<&2, U32>>:
  match m r:
    case Some{+x} Some{xs}:
      Bool.pick(Maybe<&2, List<&2, U32>>, U32.is_lt(x, 18), Some{x <> xs}, None{})
    case _ _:
      None{}

def cube.read.go(ws: List<&2, String>) -> Maybe<&2, List<&2, U32>>:
  match ws:
    case Nil{}:
      Some{Nil{}}
    case Con{+w, t}:
      cube.read.cons(U32.read(w), cube.read.go(t))

# "3.10.17" as moves; "" is no moves; None if a word is not a move 0..17
def cube.read(s: String) -> Maybe<&2, List<&2, U32>>:
  match s:
    case SNil{}:
      Some{Nil{}}
    case SCon{c, t}:
      cube.read.go(String.split(SCon{c, t}, '.'))
