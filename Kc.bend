import Base
import ./Cube.bend as C
import ./Coord.bend as K
import ./Sym.bend as Y

# The faster solver's tables (Kociemba's optimal solver, 2016, with the
# eight turns that keep the U-D axis): every cube's exact distance to the
# cubes whose edges are unflipped, whose corners are untwisted, and whose U-D
# slice edges are home in order, by its flip, slice and twist. That is a
# lower bound on the cube's own distance. Looked up three times, for the cube
# as it is and turned by URF3 and URF3^2 (Sym.bend), and with Coord.bend's
# exact corners, it bounds a search tighter than three tables of parts.
#
# A cube's (raw, twist) is in the class of raw (Sym.bend): raw turned by s
# is the class's raw, and the twist turned by s goes with it; the distance
# is the same. So the table holds, for each class and each twist, a
# distance: 4 bits, at class * 274 + twist / 8 (2192 slots a class, the
# last five unused). 15 is a distance not found yet.
#
# All of it is one Array<U32> of 2^30 words (4 GiB):
#   [0, 2^26)    Coord.bend's moves and exact tables (corners; edges A, B)
#   kc.FM        flip moves, f * 18 + m
#   kc.SM        slice moves, s * 18 + m
#   kc.TC        twists turned, t * 8 + s
#   kc.CMU       the moves turned by URF3, m
#   kc.REP       a class's raw
#   kc.STAB      the turns that keep a class's raw (bit s)
#   kc.CL        a raw's class: class * 16 + 8 (if some turn but 0 keeps
#                the class's raw) + s, raw turned by s being the class's
#   kc.P         the distances
#
# Every def is prefixed `kc.`.

def kc.FM() -> U32:
  35000000

def kc.SM() -> U32:
  35100000

def kc.TC() -> U32:
  35400000

def kc.CMU() -> U32:
  35500000

def kc.REP() -> U32:
  36000000

def kc.STAB() -> U32:
  40000000

def kc.CL() -> U32:
  44000000

def kc.P() -> U32:
  69000000

def kc.nraw() -> Nat:
  24330240n

# the distance (4 bits) at entry i (of 8) of word w
def kc.nib(+w: U32, +i: U32) -> U32:
  U32.and(U32.shrn(w, U32.to_nat(U32.shln(U32.and(i, 7), 2n))), 15)

# The small tables
# ----------------

def kc.fm.row(ms: List<&2, C.Cube>, +eo: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+m, t}:
      match m:
        case C.Cube{mcp, mco, mep, meo}:
          Y.sy.flip(C.cube.mul.o(eo, mep, meo, 2)) <> kc.fm.row(t, eo)

def kc.fill.fm(n: Nat, t: Array<U32>, +f: U32, +ms: List<&2, C.Cube>) -> Array<U32>:
  match n:
    case 0n:
      t
    case 1n+p:
      +row = kc.fm.row(ms, Y.sy.unflip(f))
      kc.fill.fm(p, K.co.write(row, t, U32.add(kc.FM(), U32.mul(f, 18))), U32.add(f, 1), ms)

def kc.sm.row(ms: List<&2, K.EMove>, +qs: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{+m, t}:
      match m:
        case K.EMove{to, eo}:
          K.co.arr(K.co.e.to(qs, to)) <> kc.sm.row(t, qs)

def kc.fill.sm(n: Nat, t: Array<U32>, +s: U32, +ms: List<&2, K.EMove>) -> Array<U32>:
  match n:
    case 0n:
      t
    case 1n+p:
      +row = kc.sm.row(ms, Y.sy.unslice(s))
      kc.fill.sm(p, K.co.write(row, t, U32.add(kc.SM(), U32.mul(s, 18))), U32.add(s, 1), ms)

def kc.tc.row(n: Nat, +tw: U32, +s: U32) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Y.sy.twist.conj(tw, s) <> kc.tc.row(p, tw, U32.add(s, 1))

def kc.fill.tc(n: Nat, t: Array<U32>, +tw: U32) -> Array<U32>:
  match n:
    case 0n:
      t
    case 1n+p:
      kc.fill.tc(p, K.co.write(kc.tc.row(8n, tw, 0), t, U32.add(kc.TC(), U32.mul(tw, 8))), U32.add(tw, 1))

def kc.cmu.row(n: Nat, +m: U32) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Y.sy.cmu(m) <> kc.cmu.row(p, U32.add(m, 1))

# flip, slice and twist moves (twist's: Coord.bend's), the twists turned, URF3's moves
def kc.small(t: Array<U32>) -> Array<U32>:
  t1 = kc.fill.fm(2048n, t, 0, K.co.moves())
  t2 = kc.fill.sm(11880n, t1, 0, K.co.emoves())
  t3 = kc.fill.tc(2187n, t2, 0)
  K.co.write(kc.cmu.row(18n, 0), t3, kc.CMU())

# The classes
# -----------

# raw turned so that turning it by s gives raw back... each s's: the raws of
# s * e * s^-1, e raw's cube
def kc.turned(n: Nat, +raw: U32, +s: U32) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Y.sy.raw.conj(raw, s) <> kc.turned(p, raw, U32.add(s, 1))

# the turns s that keep raw: bit s of the mask
def kc.mask(rs: List<&2, U32>, +raw: U32, +s: Nat) -> U32:
  match rs:
    case Nil{}:
      0
    case Con{+r, t}:
      U32.or(U32.shln(Bool.to_u32(U32.is_eq(r, raw)), s), kc.mask(t, raw, 1n+s))

# each raw r_s of the class: class c, by s
def kc.cls.write(rs: List<&2, U32>, t: Array<U32>, +hi: U32, +s: U32) -> Array<U32>:
  match rs:
    case Nil{}:
      t
    case Con{+r, rest}:
      kc.cls.write(rest, Array.set(U32, t, U32.add(kc.CL(), r), U32.add(hi, s)), hi, U32.add(s, 1))

def kc.cls.add(+rs: List<&2, U32>, t: Array<U32>, +c: U32, +raw: U32) -> Array<U32> & U32:
  +mask = kc.mask(rs, raw, 0n)
  +hi = U32.add(U32.mul(c, 16), U32.mul(Bool.to_u32(U32.is_ne(mask, 1)), 8))
  t1 = Array.set(U32, t, U32.add(kc.REP(), c), raw)
  t2 = Array.set(U32, t1, U32.add(kc.STAB(), c), mask)
  (kc.cls.write(rs, t2, hi, 0), U32.add(c, 1))

def kc.cls.new(fresh: Bool, t: Array<U32>, +c: U32, +raw: U32) -> Array<U32> & U32:
  match fresh:
    case True{}:
      kc.cls.add(kc.turned(8n, raw, 0), t, c, raw)
    case False{}:
      (t, c)

def kc.cls.got(r: Array<U32> & U32, +c: U32, +raw: U32) -> Array<U32> & U32:
  (t, +v) = r
  kc.cls.new(U32.is_eq(v, 4294967295), t, c, raw)

def kc.cls.one(r: Array<U32> & U32, +raw: U32) -> Array<U32> & U32:
  (t, +c) = r
  kc.cls.got(t[U32.add(kc.CL(), raw)], c, raw)

# every raw from raw on (n of them): a new class if none has it yet
def kc.classes(n: Nat, r: Array<U32> & U32, +raw: U32) -> Array<U32> & U32:
  match n:
    case 0n:
      r
    case 1n+p:
      kc.classes(p, kc.cls.one(r, raw), U32.add(raw, 1))

# The table, breadth first
# ------------------------

# an entry: its class's word and its slot in it
def kc.word(+c: U32, +tw: U32) -> U32:
  U32.add(kc.P(), U32.add(U32.mul(c, 274), U32.shrn(tw, 3n)))

# A raw's move: the new (raw's class word, twist turned) as an Ent
type Ent is Data:
  Ent{+cl: U32, +tc: U32}

def kc.ch5(r: Array<U32> & U32, +cl: U32) -> Array<U32> & Ent:
  (t, +tc) = r
  (t, Ent{cl, tc})

def kc.ch4(r: Array<U32> & U32, +tw2: U32) -> Array<U32> & Ent:
  (t, +cl) = r
  kc.ch5(t[U32.add(kc.TC(), U32.add(U32.mul(tw2, 8), U32.and(cl, 7)))], cl)

def kc.ch3(r: Array<U32> & U32, +f2: U32, +s2: U32) -> Array<U32> & Ent:
  (t, +tw2) = r
  kc.ch4(t[U32.add(kc.CL(), U32.add(U32.mul(s2, 2048), f2))], tw2)

def kc.ch2(r: Array<U32> & U32, +f2: U32, +tw: U32, +m: U32) -> Array<U32> & Ent:
  (t, +s2) = r
  kc.ch3(t[U32.add(K.co.T.tw(), U32.add(U32.mul(tw, 18), m))], f2, s2)

def kc.ch1(r: Array<U32> & U32, +s: U32, +tw: U32, +m: U32) -> Array<U32> & Ent:
  (t, +f2) = r
  kc.ch2(t[U32.add(kc.SM(), U32.add(U32.mul(s, 18), m))], f2, tw, m)

# where move m takes (flip f, slice s, twist tw): its class and twist
def kc.child(t: Array<U32>, +f: U32, +s: U32, +tw: U32, +m: U32) -> Array<U32> & Ent:
  kc.ch1(t[U32.add(kc.FM(), U32.add(U32.mul(f, 18), m))], s, tw, m)

# Setting an entry (forward): the word read, its slot unseen, then lowered
# to v with an atomic and (another lane may set the same word), counted if
# it was unseen
def kc.set.fin(r: Array<U32> & U32, +i: U32, +n: U32) -> Array<U32> & U32:
  (t, +old) = r
  (t, U32.add(n, Bool.to_u32(U32.is_eq(kc.nib(old, i), 15))))

def kc.set.if(fresh: Bool, t: Array<U32>, +wi: U32, +i: U32, +v: U32, +n: U32) -> Array<U32> & U32:
  match fresh:
    case True{}:
      kc.set.fin(Array.atomic.and(t, wi, U32.xor(4294967295, U32.shln(U32.xor(15, v), U32.to_nat(U32.shln(i, 2n))))), i, n)
    case False{}:
      (t, n)

def kc.set.got(r: Array<U32> & U32, +wi: U32, +i: U32, +v: U32, +n: U32) -> Array<U32> & U32:
  (t, +w) = r
  kc.set.if(U32.is_eq(kc.nib(w, i), 15), t, wi, i, v, n)

def kc.set(t: Array<U32>, +c: U32, +tw: U32, +v: U32, +n: U32) -> Array<U32> & U32:
  +wi = kc.word(c, tw)
  kc.set.got(t[wi], wi, U32.and(tw, 7), v, n)

# and its turned twins, if a turn keeps the class's raw: (c, tw turned by s)
# for each s in the mask
def kc.twin.got(r: Array<U32> & U32, +c: U32, +v: U32, +n: U32) -> Array<U32> & U32:
  (t, +tw2) = r
  kc.set(t, c, tw2, v, n)

def kc.twin.if(on: Bool, r: Array<U32> & U32, +c: U32, +tw: U32, +v: U32, +s: U32) -> Array<U32> & U32:
  match on:
    case True{}:
      (t, +n) = r
      kc.twin.got(t[U32.add(kc.TC(), U32.add(U32.mul(tw, 8), s))], c, v, n)
    case False{}:
      r

def kc.twins(k: Nat, r: Array<U32> & U32, +mask: U32, +c: U32, +tw: U32, +v: U32, +s: U32) -> Array<U32> & U32:
  match k:
    case 0n:
      r
    case 1n+p:
      kc.twins(p, kc.twin.if(U32.is_ne(U32.and(U32.shrn(mask, U32.to_nat(s)), 1), 0), r, c, tw, v, s), mask, c, tw, v, U32.add(s, 1))

def kc.stab.got(r: Array<U32> & U32, +n: U32, +c: U32, +tw: U32, +v: U32) -> Array<U32> & U32:
  (t, +mask) = r
  kc.twins(7n, (t, n), mask, c, tw, v, 1)

def kc.stab.if(on: Bool, r: Array<U32> & U32, +c: U32, +tw: U32, +v: U32) -> Array<U32> & U32:
  match on:
    case True{}:
      (t, +n) = r
      kc.stab.got(t[U32.add(kc.STAB(), c)], n, c, tw, v)
    case False{}:
      r

# an entry set to v, with its twins
def kc.put(t: Array<U32>, +c: U32, +tw: U32, +v: U32, +n: U32, +has: Bool) -> Array<U32> & U32:
  kc.stab.if(has, kc.set(t, c, tw, v, n), c, tw, v)

def kc.put.ent(r: Array<U32> & Ent, +v: U32, +n: U32) -> Array<U32> & U32:
  (t, e) = r
  match e:
    case Ent{+cl, +tc}:
      kc.put(t, U32.shrn(cl, 4n), tc, v, n, U32.is_ne(U32.and(cl, 8), 0))

# Forward: each move of an entry at distance d sets its child to d + 1
def kc.fwd.ms(k: Nat, r: Array<U32> & U32, +f: U32, +s: U32, +tw: U32, +v: U32, +m: U32) -> Array<U32> & U32:
  match k:
    case 0n:
      r
    case 1n+p:
      (t, +n) = r
      kc.fwd.ms(p, kc.put.ent(kc.child(t, f, s, tw, m), v, n), f, s, tw, v, U32.add(m, 1))

# Backward: an unseen entry is d + 1 if one of its moves reaches d; found
# says one has
def kc.bwd.read(r: Array<U32> & U32, +tc: U32, +d: U32) -> Array<U32> & Bool:
  (t, +w) = r
  (t, U32.is_eq(kc.nib(w, U32.and(tc, 7)), d))

def kc.bwd.hit(r: Array<U32> & Ent, +d: U32) -> Array<U32> & Bool:
  (t, e) = r
  match e:
    case Ent{+cl, +tc}:
      kc.bwd.read(t[kc.word(U32.shrn(cl, 4n), tc)], tc, d)

def kc.bwd.next(b: Bool, t: Array<U32>, +f: U32, +s: U32, +tw: U32, +d: U32, +m: U32) -> Array<U32> & Bool:
  match b:
    case True{}:
      (t, True{})
    case False{}:
      kc.bwd.hit(kc.child(t, f, s, tw, m), d)

def kc.bwd.ms(k: Nat, found: Bool, r: Array<U32> & Bool, +f: U32, +s: U32, +tw: U32, +d: U32, +m: U32) -> Array<U32> & Bool:
  match k found:
    case 0n _:
      r
    case 1n+p True{}:
      r
    case 1n+p False{}:
      (t, +b) = r
      kc.bwd.ms(p, b, kc.bwd.next(b, t, f, s, tw, d, m), f, s, tw, d, U32.add(m, 1))

def kc.bwd.set(r: Array<U32> & Bool, +c: U32, +tw: U32, +v: U32, +n: U32) -> Array<U32> & U32:
  (t, b) = r
  match b:
    case True{}:
      kc.set(t, c, tw, v, n)
    case False{}:
      (t, n)

# One entry (class c, twist tw) of a level: its raw read, then its moves
def kc.ent.raw(back: Bool, r: Array<U32> & U32, +n: U32, +c: U32, +tw: U32, +d: U32) -> Array<U32> & U32:
  match back:
    case False{}:
      (t, +raw) = r
      kc.fwd.ms(18n, (t, n), U32.and(raw, 2047), U32.shrn(raw, 11n), tw, U32.add(d, 1), 0)
    case True{}:
      (t, +raw) = r
      kc.bwd.set(kc.bwd.ms(18n, False{}, (t, False{}), U32.and(raw, 2047), U32.shrn(raw, 11n), tw, d, 0), c, tw, U32.add(d, 1), n)

def kc.ent.if(on: Bool, r: Array<U32> & U32, +c: U32, +tw: U32, +d: U32, back: Bool) -> Array<U32> & U32:
  match on:
    case True{}:
      (t, +n) = r
      kc.ent.raw(back, t[U32.add(kc.REP(), c)], n, c, tw, d)
    case False{}:
      r

# the distance looked for: d forward, unseen (15) backward
def kc.want(+d: U32, +back: Bool) -> U32:
  Bool.pick(U32, back, 15, d)

def kc.nibs(k: Nat, r: Array<U32> & U32, +w: U32, +c: U32, +tw: U32, +d: U32, +back: Bool) -> Array<U32> & U32:
  match k:
    case 0n:
      r
    case 1n+p:
      +on = Bool.and(U32.is_eq(kc.nib(w, U32.and(tw, 7)), kc.want(d, back)), U32.is_lt(tw, 2187))
      kc.nibs(p, kc.ent.if(on, r, c, tw, d, back), w, c, U32.add(tw, 1), d, back)

# whether some entry of w is x: a zero nibble of w xor x x x .. x
def kc.has(+w: U32, +x: U32) -> Bool:
  +y = U32.xor(w, U32.mul(x, 286331153))
  U32.is_ne(U32.and(U32.and(U32.sub(y, 286331153), U32.xor(y, 4294967295)), 2290649224), 0)

def kc.wd.if(on: Bool, r: Array<U32> & U32, +w: U32, +k: U32, +d: U32, +back: Bool) -> Array<U32> & U32:
  match on:
    case True{}:
      kc.nibs(8n, r, w, U32.div(k, 274), U32.shln(U32.mod(k, 274), 3n), d, back)
    case False{}:
      r

def kc.wd.got(r: Array<U32> & U32, +n: U32, +k: U32, +d: U32, +back: Bool) -> Array<U32> & U32:
  (t, +w) = r
  kc.wd.if(kc.has(w, kc.want(d, back)), (t, n), w, k, d, back)

def kc.wd(r: Array<U32> & U32, +k: U32, +d: U32, +back: Bool) -> Array<U32> & U32:
  (t, +n) = r
  kc.wd.got(t[U32.add(kc.P(), k)], n, k, d, back)

# A level over words k.. (n of them): forward, every entry at d sets its
# children's to d + 1; backward, every unseen one is d + 1 if a child is d.
# Answers the array and how many entries it set.
def kc.level(n: Nat, r: Array<U32> & U32, +k: U32, +d: U32, +back: Bool) -> Array<U32> & U32:
  match n:
    case 0n:
      r
    case 1n+p:
      kc.level(p, kc.wd(r, k, d, back), U32.add(k, 1), d, back)

# The start: the solved cube's entry, 0
def kc.seed.got(r: Array<U32> & U32) -> Array<U32> & U32:
  (t, +cl) = r
  kc.put(t, U32.shrn(cl, 4n), 0, 0, 0, U32.is_ne(U32.and(cl, 8), 0))

def kc.seed(t: Array<U32>) -> Array<U32> & U32:
  kc.seed.got(t[U32.add(kc.CL(), Y.sy.raw(C.cube.solved()))])
