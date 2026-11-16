import Base
import ./Cube.bend as C
import ./Coord.bend as K
import ./Sym.bend as Y
import ./Lite.bend as L
import ./Search.bend as S

# The device's shortest search, with Kociemba's optimal solver's bound made
# small enough for a browser.
#
# The bound: every cube's exact distance to Lite.bend's phase-1 goal S (edges
# unflipped, corners untwisted, the four U-D slice edges in the U-D slice, in
# any order), by its flip (2048), its slice edges' places (495, Lite.bend's
# u) and its twist (2187): 2.2 billion cubes, kept by class under the eight
# turns that keep the U-D axis (Sym.bend; Kc.bend's way, with the slice
# edges' order left out). A cube turned so is as far from S, so the table
# holds a class's raw (u * 2048 + flip) with each twist. Each entry is the
# distance mod 3, 2 bits (Kociemba's encoding): the search knows its node's
# distance exactly, a move changes it by at most one, so mod 3 says which.
# Looked up for the cube as it is and turned by URF3 and URF3^2 (its R-L and
# F-B axes taken as U-D), with Coord.bend's exact corners: the bound is the
# largest of the four. Korf's two tables of six edges are not used any more:
# this bound is the stronger by about one move, each move ~13x the nodes.
#
# Where it sits in the device's array (Dev.bend's; below kd.PC, Coord.bend's
# cp and tw moves, made on the device; from lt.FM on, Lite.bend's):
#   kd.PC   Coord.bend's corners' exact distances, 4 bits (co.T.pc's, moved)
#   kd.P    the distances mod 3, 16 a word, at class * 2187 + twist
#   kd.CL   a raw's class: class * 16 + 8 (if a turn other than 0 keeps the
#           class's raw) + s, raw turned by s being the class's
#   kd.TC   twists turned, t * 8 + s
#   kd.CMU  the moves turned by URF3, m
# all made once by FstTables.bend; there only: kd.REP (a class's raw),
# kd.STAB (the turns that keep it), kd.MK (Lite.bend's 495 masks) and kd.P4
# (the distances at 4 bits, 15 not found yet, breadth first as Kc.bend's).
#
# Every def is prefixed `kd.`.

def kd.PC() -> U32:
  1048576

def kd.P() -> U32:
  12071056

def kd.CL() -> U32:
  31000000

def kd.TC() -> U32:
  32100000

def kd.CMU() -> U32:
  32120000

def kd.end() -> U32:
  32120018

def kd.REP() -> U32:
  32200000

def kd.STAB() -> U32:
  32400000

def kd.MK() -> U32:
  32600000

def kd.P4() -> U32:
  40000000

def kd.nraw() -> Nat:
  1013760n

# classes kd.P has room for
def kd.cap() -> U32:
  138483

# the distance (4 bits) at entry i (of 8) of word w
def kd.nib(+w: U32, +i: U32) -> U32:
  U32.and(U32.shrn(w, U32.to_nat(U32.shln(U32.and(i, 7), 2n))), 15)

# the distance mod 3 (2 bits) at entry e (of 16) of word w
def kd.two(+w: U32, +e: U32) -> U32:
  U32.and(U32.shrn(w, U32.to_nat(U32.shln(U32.and(e, 15), 1n))), 3)

# A neighbour's exact distance from its residue r: d's neighbours are d - 1,
# d or d + 1 away, and those are three residues mod 3
def kd.step(+d: U32, +r: U32) -> U32:
  +x = U32.mod(U32.sub(U32.add(r, 3), U32.mod(d, 3)), 3)
  Bool.pick(U32, U32.is_eq(x, 0), d, Bool.pick(U32, U32.is_eq(x, 1), U32.add(d, 1), U32.sub(d, 1)))

# The small tables (FstTables.bend)
# ---------------------------------

def kd.tc.row(n: Nat, +tw: U32, +s: U32) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Y.sy.twist.conj(tw, s) <> kd.tc.row(p, tw, U32.add(s, 1))

def kd.fill.tc(n: Nat, t: Array<U32>, +tw: U32) -> Array<U32>:
  match n:
    case 0n:
      t
    case 1n+p:
      kd.fill.tc(p, K.co.write(kd.tc.row(8n, tw, 0), t, U32.add(kd.TC(), U32.mul(tw, 8))), U32.add(tw, 1))

def kd.cmu.row(n: Nat, +m: U32) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Y.sy.cmu(m) <> kd.cmu.row(p, U32.add(m, 1))

# twist moves (Coord.bend's), flip and slice-place moves (Lite.bend's), the
# twists turned, URF3's moves, the masks
def kd.small(t: Array<U32>) -> Array<U32>:
  +ms = K.co.moves()
  +ks = L.lt.masks()
  t1 = K.co.fill.tw(2187n, t, 0, ms)
  t2 = L.lt.fill.u5(ks, L.lt.fill.fm(2048n, t1, 0, ms), 0, K.co.emoves(), ks)
  t3 = kd.fill.tc(2187n, t2, 0)
  t4 = K.co.write(ks, t3, kd.MK())
  K.co.write(kd.cmu.row(18n, 0), t4, kd.CMU())

# The classes
# -----------

# raw's cube (mask x its slice edges' places): FR FL BL BR in those places in
# order, the other edges in order, the flips raw's, the corners home
def kd.ecube(+x: U32, +raw: U32) -> C.Cube:
  C.Cube{[0, 1, 2, 3, 4, 5, 6, 7], [0, 0, 0, 0, 0, 0, 0, 0],
         Y.sy.ep.go(12n, L.lt.places(12n, x, 0), 0, 0), Y.sy.unflip(U32.and(raw, 2047))}

# a cube's raw, given the masks
def kd.raw.of(+ks: List<&2, U32>, +c: C.Cube) -> U32:
  match c:
    case C.Cube{cp, co, +ep, +eo}:
      U32.add(U32.mul(L.lt.rank(ks, K.co.places([8, 9, 10, 11], ep)), 2048), Y.sy.flip(eo))

# raw turned: the raw of s * e * s^-1 (so that raw is the result turned by s)
def kd.raw.conj(+ks: List<&2, U32>, +x: U32, +raw: U32, +s: U32) -> U32:
  +t = Y.sy.sym.n(s)
  kd.raw.of(ks, C.cube.mul(C.cube.mul(t, kd.ecube(x, raw)), Y.sy.inv(t)))

def kd.turned(n: Nat, +ks: List<&2, U32>, +x: U32, +raw: U32, +s: U32) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      kd.raw.conj(ks, x, raw, s) <> kd.turned(p, ks, x, raw, U32.add(s, 1))

# the turns s that keep raw: bit s of the mask
def kd.mask(rs: List<&2, U32>, +raw: U32, +s: Nat) -> U32:
  match rs:
    case Nil{}:
      0
    case Con{+r, t}:
      U32.or(U32.shln(Bool.to_u32(U32.is_eq(r, raw)), s), kd.mask(t, raw, 1n+s))

# each raw r_s of the class: class c, by s
def kd.cls.write(rs: List<&2, U32>, t: Array<U32>, +hi: U32, +s: U32) -> Array<U32>:
  match rs:
    case Nil{}:
      t
    case Con{+r, rest}:
      kd.cls.write(rest, Array.set(U32, t, U32.add(kd.CL(), r), U32.add(hi, s)), hi, U32.add(s, 1))

def kd.cls.add(+rs: List<&2, U32>, t: Array<U32>, +c: U32, +raw: U32) -> Array<U32> & U32:
  +mask = kd.mask(rs, raw, 0n)
  +hi = U32.add(U32.mul(c, 16), U32.mul(Bool.to_u32(U32.is_ne(mask, 1)), 8))
  t1 = Array.set(U32, t, U32.add(kd.REP(), c), raw)
  t2 = Array.set(U32, t1, U32.add(kd.STAB(), c), mask)
  (kd.cls.write(rs, t2, hi, 0), U32.add(c, 1))

def kd.cls.mk(r: Array<U32> & U32, +ks: List<&2, U32>, +c: U32, +raw: U32) -> Array<U32> & U32:
  (t, +x) = r
  kd.cls.add(kd.turned(8n, ks, x, raw, 0), t, c, raw)

def kd.cls.new(fresh: Bool, t: Array<U32>, +ks: List<&2, U32>, +c: U32, +raw: U32) -> Array<U32> & U32:
  match fresh:
    case True{}:
      kd.cls.mk(t[U32.add(kd.MK(), U32.shrn(raw, 11n))], ks, c, raw)
    case False{}:
      (t, c)

def kd.cls.got(r: Array<U32> & U32, +ks: List<&2, U32>, +c: U32, +raw: U32) -> Array<U32> & U32:
  (t, +v) = r
  kd.cls.new(U32.is_eq(v, 4294967295), t, ks, c, raw)

def kd.cls.one(r: Array<U32> & U32, +ks: List<&2, U32>, +raw: U32) -> Array<U32> & U32:
  (t, +c) = r
  kd.cls.got(t[U32.add(kd.CL(), raw)], ks, c, raw)

# every raw from raw on (n of them): a new class if none has it yet
def kd.classes(n: Nat, r: Array<U32> & U32, +ks: List<&2, U32>, +raw: U32) -> Array<U32> & U32:
  match n:
    case 0n:
      r
    case 1n+p:
      kd.classes(p, kd.cls.one(r, ks, raw), ks, U32.add(raw, 1))

# The table at 4 bits, breadth first (Kc.bend's levels)
# -----------------------------------------------------

# an entry: its class's word and its slot in it
def kd.word(+c: U32, +tw: U32) -> U32:
  U32.add(kd.P4(), U32.add(U32.mul(c, 274), U32.shrn(tw, 3n)))

# A raw's move: the new (raw's class word, twist turned) as an Ent
type Ent is Data:
  Ent{+cl: U32, +tc: U32}

def kd.ch5(r: Array<U32> & U32, +cl: U32) -> Array<U32> & Ent:
  (t, +tc) = r
  (t, Ent{cl, tc})

def kd.ch4(r: Array<U32> & U32, +tw2: U32) -> Array<U32> & Ent:
  (t, +cl) = r
  kd.ch5(t[U32.add(kd.TC(), U32.add(U32.mul(tw2, 8), U32.and(cl, 7)))], cl)

def kd.ch3(r: Array<U32> & U32, +f2: U32, +s2: U32) -> Array<U32> & Ent:
  (t, +tw2) = r
  kd.ch4(t[U32.add(kd.CL(), U32.add(U32.mul(s2, 2048), f2))], tw2)

def kd.ch2(r: Array<U32> & U32, +f2: U32, +tw: U32, +m: U32) -> Array<U32> & Ent:
  (t, +s2) = r
  kd.ch3(t[U32.add(K.co.T.tw(), U32.add(U32.mul(tw, 18), m))], f2, s2)

def kd.ch1(r: Array<U32> & U32, +s: U32, +tw: U32, +m: U32) -> Array<U32> & Ent:
  (t, +f2) = r
  kd.ch2(t[U32.add(L.lt.U5M(), U32.add(U32.mul(s, 18), m))], f2, tw, m)

# where move m takes (flip f, places s, twist tw): its class and twist
def kd.child(t: Array<U32>, +f: U32, +s: U32, +tw: U32, +m: U32) -> Array<U32> & Ent:
  kd.ch1(t[U32.add(L.lt.FM(), U32.add(U32.mul(f, 18), m))], s, tw, m)

# Setting an entry (forward): lowered to v with an atomic and (another lane
# may set the same word), counted if it was unseen
def kd.set.fin(r: Array<U32> & U32, +i: U32, +n: U32) -> Array<U32> & U32:
  (t, +old) = r
  (t, U32.add(n, Bool.to_u32(U32.is_eq(kd.nib(old, i), 15))))

def kd.set.if(fresh: Bool, t: Array<U32>, +wi: U32, +i: U32, +v: U32, +n: U32) -> Array<U32> & U32:
  match fresh:
    case True{}:
      kd.set.fin(Array.atomic.and(t, wi, U32.xor(4294967295, U32.shln(U32.xor(15, v), U32.to_nat(U32.shln(i, 2n))))), i, n)
    case False{}:
      (t, n)

def kd.set.got(r: Array<U32> & U32, +wi: U32, +i: U32, +v: U32, +n: U32) -> Array<U32> & U32:
  (t, +w) = r
  kd.set.if(U32.is_eq(kd.nib(w, i), 15), t, wi, i, v, n)

def kd.set(t: Array<U32>, +c: U32, +tw: U32, +v: U32, +n: U32) -> Array<U32> & U32:
  +wi = kd.word(c, tw)
  kd.set.got(t[wi], wi, U32.and(tw, 7), v, n)

# and its turned twins, if a turn keeps the class's raw
def kd.twin.got(r: Array<U32> & U32, +c: U32, +v: U32, +n: U32) -> Array<U32> & U32:
  (t, +tw2) = r
  kd.set(t, c, tw2, v, n)

def kd.twin.if(on: Bool, r: Array<U32> & U32, +c: U32, +tw: U32, +v: U32, +s: U32) -> Array<U32> & U32:
  match on:
    case True{}:
      (t, +n) = r
      kd.twin.got(t[U32.add(kd.TC(), U32.add(U32.mul(tw, 8), s))], c, v, n)
    case False{}:
      r

def kd.twins(k: Nat, r: Array<U32> & U32, +mask: U32, +c: U32, +tw: U32, +v: U32, +s: U32) -> Array<U32> & U32:
  match k:
    case 0n:
      r
    case 1n+p:
      kd.twins(p, kd.twin.if(U32.is_ne(U32.and(U32.shrn(mask, U32.to_nat(s)), 1), 0), r, c, tw, v, s), mask, c, tw, v, U32.add(s, 1))

def kd.stab.got(r: Array<U32> & U32, +n: U32, +c: U32, +tw: U32, +v: U32) -> Array<U32> & U32:
  (t, +mask) = r
  kd.twins(7n, (t, n), mask, c, tw, v, 1)

def kd.stab.if(on: Bool, r: Array<U32> & U32, +c: U32, +tw: U32, +v: U32) -> Array<U32> & U32:
  match on:
    case True{}:
      (t, +n) = r
      kd.stab.got(t[U32.add(kd.STAB(), c)], n, c, tw, v)
    case False{}:
      r

def kd.put(t: Array<U32>, +c: U32, +tw: U32, +v: U32, +n: U32, +has: Bool) -> Array<U32> & U32:
  kd.stab.if(has, kd.set(t, c, tw, v, n), c, tw, v)

def kd.put.ent(r: Array<U32> & Ent, +v: U32, +n: U32) -> Array<U32> & U32:
  (t, e) = r
  match e:
    case Ent{+cl, +tc}:
      kd.put(t, U32.shrn(cl, 4n), tc, v, n, U32.is_ne(U32.and(cl, 8), 0))

# Forward: each move of an entry at distance d sets its child to d + 1
def kd.fwd.ms(k: Nat, r: Array<U32> & U32, +f: U32, +s: U32, +tw: U32, +v: U32, +m: U32) -> Array<U32> & U32:
  match k:
    case 0n:
      r
    case 1n+p:
      (t, +n) = r
      kd.fwd.ms(p, kd.put.ent(kd.child(t, f, s, tw, m), v, n), f, s, tw, v, U32.add(m, 1))

# Backward: an unseen entry is d + 1 if one of its moves reaches d
def kd.bwd.read(r: Array<U32> & U32, +tc: U32, +d: U32) -> Array<U32> & Bool:
  (t, +w) = r
  (t, U32.is_eq(kd.nib(w, U32.and(tc, 7)), d))

def kd.bwd.hit(r: Array<U32> & Ent, +d: U32) -> Array<U32> & Bool:
  (t, e) = r
  match e:
    case Ent{+cl, +tc}:
      kd.bwd.read(t[kd.word(U32.shrn(cl, 4n), tc)], tc, d)

def kd.bwd.next(b: Bool, t: Array<U32>, +f: U32, +s: U32, +tw: U32, +d: U32, +m: U32) -> Array<U32> & Bool:
  match b:
    case True{}:
      (t, True{})
    case False{}:
      kd.bwd.hit(kd.child(t, f, s, tw, m), d)

def kd.bwd.ms(k: Nat, found: Bool, r: Array<U32> & Bool, +f: U32, +s: U32, +tw: U32, +d: U32, +m: U32) -> Array<U32> & Bool:
  match k found:
    case 0n _:
      r
    case 1n+p True{}:
      r
    case 1n+p False{}:
      (t, +b) = r
      kd.bwd.ms(p, b, kd.bwd.next(b, t, f, s, tw, d, m), f, s, tw, d, U32.add(m, 1))

def kd.bwd.set(r: Array<U32> & Bool, +c: U32, +tw: U32, +v: U32, +n: U32) -> Array<U32> & U32:
  (t, b) = r
  match b:
    case True{}:
      kd.set(t, c, tw, v, n)
    case False{}:
      (t, n)

def kd.ent.raw(back: Bool, r: Array<U32> & U32, +n: U32, +c: U32, +tw: U32, +d: U32) -> Array<U32> & U32:
  match back:
    case False{}:
      (t, +raw) = r
      kd.fwd.ms(18n, (t, n), U32.and(raw, 2047), U32.shrn(raw, 11n), tw, U32.add(d, 1), 0)
    case True{}:
      (t, +raw) = r
      kd.bwd.set(kd.bwd.ms(18n, False{}, (t, False{}), U32.and(raw, 2047), U32.shrn(raw, 11n), tw, d, 0), c, tw, U32.add(d, 1), n)

def kd.ent.if(on: Bool, r: Array<U32> & U32, +c: U32, +tw: U32, +d: U32, back: Bool) -> Array<U32> & U32:
  match on:
    case True{}:
      (t, +n) = r
      kd.ent.raw(back, t[U32.add(kd.REP(), c)], n, c, tw, d)
    case False{}:
      r

def kd.want(+d: U32, +back: Bool) -> U32:
  Bool.pick(U32, back, 15, d)

def kd.nibs(k: Nat, r: Array<U32> & U32, +w: U32, +c: U32, +tw: U32, +d: U32, +back: Bool) -> Array<U32> & U32:
  match k:
    case 0n:
      r
    case 1n+p:
      +on = Bool.and(U32.is_eq(kd.nib(w, U32.and(tw, 7)), kd.want(d, back)), U32.is_lt(tw, 2187))
      kd.nibs(p, kd.ent.if(on, r, c, tw, d, back), w, c, U32.add(tw, 1), d, back)

# whether some entry of w is x: a zero nibble of w xor x x x .. x
def kd.has(+w: U32, +x: U32) -> Bool:
  +y = U32.xor(w, U32.mul(x, 286331153))
  U32.is_ne(U32.and(U32.and(U32.sub(y, 286331153), U32.xor(y, 4294967295)), 2290649224), 0)

def kd.wd.if(on: Bool, r: Array<U32> & U32, +w: U32, +k: U32, +d: U32, +back: Bool) -> Array<U32> & U32:
  match on:
    case True{}:
      kd.nibs(8n, r, w, U32.div(k, 274), U32.shln(U32.mod(k, 274), 3n), d, back)
    case False{}:
      r

def kd.wd.got(r: Array<U32> & U32, +n: U32, +k: U32, +d: U32, +back: Bool) -> Array<U32> & U32:
  (t, +w) = r
  kd.wd.if(kd.has(w, kd.want(d, back)), (t, n), w, k, d, back)

def kd.wd(r: Array<U32> & U32, +k: U32, +d: U32, +back: Bool) -> Array<U32> & U32:
  (t, +n) = r
  kd.wd.got(t[U32.add(kd.P4(), k)], n, k, d, back)

# A level over words k.. (n of them); answers how many entries it set
def kd.level(n: Nat, r: Array<U32> & U32, +k: U32, +d: U32, +back: Bool) -> Array<U32> & U32:
  match n:
    case 0n:
      r
    case 1n+p:
      kd.level(p, kd.wd(r, k, d, back), U32.add(k, 1), d, back)

# The start: S's entry (flip 0, the slice edges home, twist 0), 0
def kd.seed.got(r: Array<U32> & U32) -> Array<U32> & U32:
  (t, +cl) = r
  kd.put(t, U32.shrn(cl, 4n), 0, 0, 0, U32.is_ne(U32.and(cl, 8), 0))

def kd.seed(t: Array<U32>) -> Array<U32> & U32:
  kd.seed.got(t[U32.add(kd.CL(), kd.raw.of(L.lt.masks(), C.cube.solved()))])

# Packed: 2 bits an entry, the distance mod 3
def kd.pk.got(r: Array<U32> & U32, +acc: U32, +tw: U32, +i: U32) -> Array<U32> & U32:
  (t, +w) = r
  (t, U32.or(acc, U32.shln(U32.mod(kd.nib(w, tw), 3), U32.to_nat(U32.shln(i, 1n)))))

def kd.pk.one(r: Array<U32> & U32, +e: U32, +i: U32) -> Array<U32> & U32:
  (t, +acc) = r
  +tw = U32.mod(e, 2187)
  kd.pk.got(t[kd.word(U32.div(e, 2187), tw)], acc, tw, i)

def kd.pk.word(k: Nat, r: Array<U32> & U32, +e: U32, +i: U32) -> Array<U32> & U32:
  match k:
    case 0n:
      r
    case 1n+p:
      kd.pk.word(p, kd.pk.one(r, e, i), U32.add(e, 1), U32.add(i, 1))

def kd.pk.set(r: Array<U32> & U32, +j: U32) -> Array<U32>:
  (t, +w) = r
  Array.set(U32, t, U32.add(kd.P(), j), w)

# words j .. j + n of kd.P
def kd.pack(n: Nat, t: Array<U32>, +j: U32) -> Array<U32>:
  match n:
    case 0n:
      t
    case 1n+p:
      kd.pack(p, kd.pk.set(kd.pk.word(16n, (t, 0), U32.mul(j, 16), 0), j), U32.add(j, 1))

# The lookups (on the device)
# ---------------------------

# entry (raw, twist)'s distance mod 3
def kd.m3.w(r: Array<U32> & U32, +e: U32) -> Array<U32> & U32:
  (t, +w) = r
  (t, kd.two(w, e))

def kd.m3.tc(r: Array<U32> & U32, +cl: U32) -> Array<U32> & U32:
  (t, +tc) = r
  +e = U32.add(U32.mul(U32.shrn(cl, 4n), 2187), tc)
  kd.m3.w(t[U32.add(kd.P(), U32.shrn(e, 4n))], e)

def kd.m3.cl(r: Array<U32> & U32, +tw: U32) -> Array<U32> & U32:
  (t, +cl) = r
  kd.m3.tc(t[U32.add(kd.TC(), U32.add(U32.mul(tw, 8), U32.and(cl, 7)))], cl)

def kd.m3(t: Array<U32>, +raw: U32, +tw: U32) -> Array<U32> & U32:
  kd.m3.cl(t[U32.add(kd.CL(), raw)], tw)

# One axis's coordinates: flip, the slice edges' places, twist; and with its
# exact distance to S
type F3 is Data:
  F3{+f: U32, +u: U32, +tw: U32}

type Ax is Data:
  Ax{+f: U32, +u: U32, +tw: U32, +d: U32}

def kd.mv3(r: Array<U32> & U32, +f2: U32, +u2: U32) -> Array<U32> & F3:
  (t, +tw2) = r
  (t, F3{f2, u2, tw2})

def kd.mv2(r: Array<U32> & U32, +f2: U32, +tw: U32, +m: U32) -> Array<U32> & F3:
  (t, +u2) = r
  kd.mv3(t[U32.add(K.co.T.tw(), U32.add(U32.mul(tw, 18), m))], f2, u2)

def kd.mv1(r: Array<U32> & U32, +u: U32, +tw: U32, +m: U32) -> Array<U32> & F3:
  (t, +f2) = r
  kd.mv2(t[U32.add(L.lt.U5M(), U32.add(U32.mul(u, 18), m))], f2, tw, m)

# move m's coordinates
def kd.mv(t: Array<U32>, +f: U32, +u: U32, +tw: U32, +m: U32) -> Array<U32> & F3:
  kd.mv1(t[U32.add(L.lt.FM(), U32.add(U32.mul(f, 18), m))], u, tw, m)

# The exact distance to S: down a neighbour one closer (the one whose residue
# is one below) until S, counted (Bend's loops: each step a def of its own,
# the loop the one def that calls itself)
type Fd is Data:
  NoF{}
  Fd{+x: F3}

def kd.dn.v(r: Array<U32> & U32, +want: U32, +x: F3) -> Array<U32> & Fd:
  (t, +v) = r
  (t, Bool.pick(Fd, U32.is_eq(v, want), Fd{x}, NoF{}))

def kd.dn.got(r: Array<U32> & F3, +want: U32) -> Array<U32> & Fd:
  (t, x) = r
  match x:
    case F3{+f2, +u2, +tw2}:
      kd.dn.v(kd.m3(t, U32.add(U32.mul(u2, 2048), f2), tw2), want, F3{f2, u2, tw2})

def kd.dn.one(r: Array<U32> & Fd, +f: U32, +u: U32, +tw: U32, +want: U32, +m: U32) -> Array<U32> & Fd:
  (t, fd) = r
  match fd:
    case NoF{}:
      kd.dn.got(kd.mv(t, f, u, tw, m), want)
    case Fd{+x}:
      (t, Fd{x})

# the first of moves m.. whose child's residue is want
def kd.down(k: Nat, r: Array<U32> & Fd, +f: U32, +u: U32, +tw: U32, +want: U32, +m: U32) -> Array<U32> & Fd:
  match k:
    case 0n:
      r
    case 1n+p:
      kd.down(p, kd.dn.one(r, f, u, tw, want, m), f, u, tw, want, U32.add(m, 1))

# where the walk down is: done, d moves from S; or at (f, u, tw), d moves down
type Ex is Data:
  ExDone{+d: U32}
  ExAt{+f: U32, +u: U32, +tw: U32, +d: U32}

def kd.ex.mv(r: Array<U32> & Fd, +d: U32) -> Array<U32> & Ex:
  (t, fd) = r
  match fd:
    case NoF{}:
      (t, ExDone{99})
    case Fd{x}:
      match x:
        case F3{+f2, +u2, +tw2}:
          (t, ExAt{f2, u2, tw2, U32.add(d, 1)})

def kd.ex.r(r: Array<U32> & U32, +f: U32, +u: U32, +tw: U32, +d: U32) -> Array<U32> & Ex:
  (t, +v) = r
  kd.ex.mv(kd.down(18n, (t, NoF{}), f, u, tw, U32.mod(U32.add(v, 2), 3), 0), d)

def kd.ex.at(goal: Bool, t: Array<U32>, +f: U32, +u: U32, +tw: U32, +d: U32) -> Array<U32> & Ex:
  match goal:
    case True{}:
      (t, ExDone{d})
    case False{}:
      kd.ex.r(kd.m3(t, U32.add(U32.mul(u, 2048), f), tw), f, u, tw, d)

def kd.ex.one(r: Array<U32> & Ex, +home: U32) -> Array<U32> & Ex:
  (t, e) = r
  match e:
    case ExDone{+d}:
      (t, ExDone{d})
    case ExAt{+f, +u, +tw, +d}:
      kd.ex.at(Bool.and(Bool.and(U32.is_zero(f), U32.is_eq(u, home)), U32.is_zero(tw)), t, f, u, tw, d)

def kd.exact(n: Nat, r: Array<U32> & Ex, +home: U32) -> Array<U32> & Ex:
  match n:
    case 0n:
      r
    case 1n+p:
      kd.exact(p, kd.ex.one(r, home), home)

# A set of 4 of the 12 edge places (a bit mask), ranked as Lite.bend's u:
# masks in increasing order are sets in colex order, so the rank is the sum,
# over the set's places p_1 < .. < p_4, of C(p_i, i) (and no list of the 495
# is made, as lt.u does, each time)
def kd.cnk(+n: U32, +k: U32) -> U32:
  +b = U32.mul(n, U32.sub(n, 1))
  +c = U32.mul(b, U32.sub(n, 2))
  Bool.pick(U32, U32.is_eq(k, 1), n, Bool.pick(U32, U32.is_eq(k, 2), U32.div(b, 2),
    Bool.pick(U32, U32.is_eq(k, 3), U32.div(c, 6), U32.div(U32.mul(c, U32.sub(n, 3)), 24))))

def kd.colex(n: Nat, +x: U32, +pos: U32, +k: U32, +acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      +on = U32.is_eq(U32.and(x, 1), 1)
      +k2 = U32.add(k, Bool.to_u32(on))
      kd.colex(p, U32.shrn(x, 1n), U32.add(pos, 1), k2, U32.add(acc, Bool.pick(U32, on, kd.cnk(pos, k2), 0)))

def kd.rank(+x: U32) -> U32:
  kd.colex(12n, x, 0, 0, 0)

# S's places (the slice edges home: places 8 .. 11)
def kd.home() -> U32:
  kd.rank(3840)

# a cube's coordinates: its twist, its raw (u * 2048 + flip), as lt.node's
def kd.node(+c: C.Cube) -> L.Node:
  match c:
    case C.Cube{cp, +co, +ep, +eo}:
      L.Node{K.co.twist(co), U32.add(U32.mul(kd.rank(L.lt.mask(K.co.places([8, 9, 10, 11], ep))), 2048), Y.sy.flip(eo))}

# a cube's axis: its coordinates and exact distance
def kd.ex.d(+e: Ex) -> U32:
  match e:
    case ExDone{+d}:
      d
    case ExAt{f, u, tw, d}:
      99

def kd.ax.got(r: Array<U32> & Ex, +f: U32, +u: U32, +tw: U32) -> Array<U32> & Ax:
  (t, +e) = r
  (t, Ax{f, u, tw, kd.ex.d(e)})

def kd.ax.node(t: Array<U32>, +n: L.Node, +home: U32) -> Array<U32> & Ax:
  match n:
    case L.Node{+tw, +rw}:
      kd.ax.got(kd.exact(14n, (t, ExAt{U32.and(rw, 2047), U32.shrn(rw, 11n), tw, 0}), home), U32.and(rw, 2047), U32.shrn(rw, 11n), tw)

def kd.ax(t: Array<U32>, +c: C.Cube, +home: U32) -> Array<U32> & Ax:
  kd.ax.node(t, kd.node(c), home)

# The search (IDA*, as Search.bend's: the same move order and rules)
# ------------------------------------------------------------------

# a child: cut (its bound passes what is left), or its corners and axes,
# and whether every bound is 0 (it may be solved: checked on the cube)
type Kid is Data:
  Cut{}
  Kid{+cp: U32, +a0: Ax, +a1: Ax, +a2: Ax, +z: Bool}

type AxR is Data:
  ACut{}
  AOk{+a: Ax, +z: Bool}

def kd.ax2(r: Array<U32> & U32, +b: U32, +d0: U32, +f: U32, +u: U32, +tw: U32) -> Array<U32> & AxR:
  (t, +v) = r
  +d = kd.step(d0, v)
  (t, Bool.pick(AxR, U32.is_ge(d, b), ACut{}, AOk{Ax{f, u, tw, d}, U32.is_zero(d)}))

def kd.ax1(r: Array<U32> & F3, +b: U32, +d0: U32) -> Array<U32> & AxR:
  (t, x) = r
  match x:
    case F3{+f, +u, +tw}:
      kd.ax2(kd.m3(t, U32.add(U32.mul(u, 2048), f), tw), b, d0, f, u, tw)

# an axis moved by m (m as that axis sees it)
def kd.axis(t: Array<U32>, +b: U32, a: Ax, +m: U32) -> Array<U32> & AxR:
  match a:
    case Ax{+f, +u, +tw, +d}:
      kd.ax1(kd.mv(t, f, u, tw, m), b, d)

def kd.k10(r: Array<U32> & AxR, +cp2: U32, +z: Bool, n0: Ax, n1: Ax) -> Array<U32> & Kid:
  (t, x) = r
  match x:
    case ACut{}:
      (t, Cut{})
    case AOk{n2, +z2}:
      (t, Kid{cp2, n0, n1, n2, Bool.and(z, z2)})

def kd.k9(r: Array<U32> & U32, +b: U32, +cp2: U32, +z: Bool, n0: Ax, n1: Ax, a2: Ax) -> Array<U32> & Kid:
  (t, +m2) = r
  kd.k10(kd.axis(t, b, a2, m2), cp2, z, n0, n1)

def kd.k8(r: Array<U32> & AxR, +b: U32, +cp2: U32, +z: Bool, n0: Ax, a2: Ax, +m1: U32) -> Array<U32> & Kid:
  (t, x) = r
  match x:
    case ACut{}:
      (t, Cut{})
    case AOk{n1, +z1}:
      kd.k9(t[U32.add(kd.CMU(), m1)], b, cp2, Bool.and(z, z1), n0, n1, a2)

def kd.k7(r: Array<U32> & U32, +b: U32, +cp2: U32, +z: Bool, n0: Ax, a1: Ax, a2: Ax) -> Array<U32> & Kid:
  (t, +m1) = r
  kd.k8(kd.axis(t, b, a1, m1), b, cp2, z, n0, a2, m1)

def kd.k6(r: Array<U32> & AxR, +b: U32, +cp2: U32, +z: Bool, a1: Ax, a2: Ax, +m: U32) -> Array<U32> & Kid:
  (t, x) = r
  match x:
    case ACut{}:
      (t, Cut{})
    case AOk{n0, +z0}:
      kd.k7(t[U32.add(kd.CMU(), m)], b, cp2, Bool.and(z, z0), n0, a1, a2)

def kd.k4(cut: Bool, t: Array<U32>, +b: U32, +cp2: U32, +z: Bool, +x: F3, +d0: U32, a1: Ax, a2: Ax, +m: U32) -> Array<U32> & Kid:
  match cut:
    case True{}:
      (t, Cut{})
    case False{}:
      kd.k6(kd.ax1((t, x), b, d0), b, cp2, z, a1, a2, m)

def kd.k3(r: Array<U32> & U32, +b: U32, +cp2: U32, +ci: U32, +x: F3, +d0: U32, a1: Ax, a2: Ax, +m: U32) -> Array<U32> & Kid:
  (t, +w) = r
  +hc = K.co.nib(w, ci)
  kd.k4(U32.is_ge(hc, b), t, b, cp2, U32.is_zero(hc), x, d0, a1, a2, m)

def kd.k2(r: Array<U32> & U32, +b: U32, +x: F3, +d0: U32, a1: Ax, a2: Ax, +m: U32) -> Array<U32> & Kid:
  (t, +cp2) = r
  match x:
    case F3{+f, +u, +tw}:
      +ci = U32.add(U32.mul(cp2, 2187), tw)
      kd.k3(t[U32.add(kd.PC(), U32.shrn(ci, 3n))], b, cp2, ci, F3{f, u, tw}, d0, a1, a2, m)

def kd.k1(r: Array<U32> & F3, +b: U32, +cp: U32, +d0: U32, a1: Ax, a2: Ax, +m: U32) -> Array<U32> & Kid:
  (t, x) = r
  kd.k2(t[U32.add(K.co.T.cp(), U32.add(U32.mul(cp, 18), m))], b, x, d0, a1, a2, m)

# move m's child of the node (cp, a0, a1, a2), b moves left: its corners
# first, then axis 0, 1, 2 (m turned by URF3 for each), each a cut at once
# if its bound passes
def kd.kid(t: Array<U32>, +b: U32, +cp: U32, a0: Ax, a1: Ax, a2: Ax, +m: U32) -> Array<U32> & Kid:
  match a0:
    case Ax{+f, +u, +tw, +d}:
      kd.k1(kd.mv(t, f, u, tw, m), b, cp, d, a1, a2, m)

# whether moves path (last first) solve c0, asked only when every bound is 0
def kd.solves(+c0: C.Cube, +path: List<&2, U32>) -> Bool:
  C.cube.is_solved(C.cube.apply(List.reverse(&2, U32, path), c0))

def kd.win.z(z: Bool, +c0: C.Cube, +path: List<&2, U32>) -> Bool:
  match z:
    case True{}:
      kd.solves(c0, path)
    case False{}:
      False{}

# whether a child (move m's, from the node path reached) is a solution
def kd.win(+k: Kid, +c0: C.Cube, +m: U32, +path: List<&2, U32>) -> Bool:
  match k:
    case Cut{}:
      False{}
    case Kid{cp, a0, a1, a2, +z}:
      kd.win.z(z, c0, m <> path)

# whether to go on: moves left and nothing found
def kd.more(+m: U32, +res: S.Res) -> Bool:
  Bool.and(U32.is_lt(m, 18), Bool.not(S.sr.found(res)))

# The array as a step leaves it: before trying move m; with m's child; with
# the child's own search done
type KS is Type:
  KTry{t: Array<U32>}
  KKid{r: Array<U32> & Kid}
  KGot{t: Array<U32>}
  KBack{r: Array<U32> & S.Res}

def kd.out(s: KS, +res: S.Res) -> Array<U32> & S.Res:
  match s:
    case KTry{t}:
      (t, res)
    case KKid{r}:
      (t, k) = r
      (t, res)
    case KGot{t}:
      (t, res)
    case KBack{r}:
      r

# The search below a node, d moves left (b: d as a U32), as Search.bend's
# sr.go: a step at a time (fuel: the steps a node may take), m the move
# tried; more, ok: whether to go on, and whether m may follow lf; kid, win:
# m's child, and whether it is a solution (the bound's first: a shortest)
def kd.go(
  +d: Nat, fuel: Nat, s: KS, kid: Kid, win: Bool, more: Bool, ok: Bool,
  +b: U32, +cp: U32, +a0: Ax, +a1: Ax, +a2: Ax, +lf: U32, +path: List<&2, U32>, +m: U32, +res: S.Res, +c0: C.Cube
) -> Array<U32> & S.Res:
  match d fuel s kid win more ok:
    case _ 0n _ _ _ _ _:
      kd.out(s, res)
    case _ 1n+fq KTry{t} _ _ False{} _:
      (t, res)
    case _ 1n+fq KTry{t} _ _ True{} False{}:
      +mn = U32.add(m, 1)
      kd.go(d, fq, KTry{t}, Cut{}, False{}, kd.more(mn, res), S.sr.allowed(mn, lf), b, cp, a0, a1, a2, lf, path, mn, res, c0)
    case _ 1n+fq KTry{t} _ _ True{} True{}:
      kd.go(d, fq, KKid{kd.kid(t, b, cp, a0, a1, a2, m)}, Cut{}, False{}, True{}, True{}, b, cp, a0, a1, a2, lf, path, m, res, c0)
    case _ 1n+fq KKid{r} _ _ _ _:
      (t, +k2) = r
      kd.go(d, fq, KGot{t}, k2, kd.win(k2, c0, m, path), True{}, True{}, b, cp, a0, a1, a2, lf, path, m, res, c0)
    case _ 1n+fq KGot{t} Kid{cp2, n0, n1, n2, z} True{} _ _:
      # a solution: the bound's first, a shortest
      kd.go(d, fq, KTry{t}, Cut{}, False{}, False{}, False{}, b, cp, a0, a1, a2, lf, path, m, S.sr.win(res, m <> path), c0)
    case 1n+dq 1n+fq KGot{t} Kid{+cp2, +n0, +n1, +n2, z} False{} _ _:
      # within the bound: below the child, then the next move here
      +f = S.sr.face(m)
      kd.go(d, fq,
        KBack{kd.go(dq, 255n, KTry{t}, Cut{}, False{}, True{}, S.sr.allowed(0, f), U32.sub(b, 1), cp2, n0, n1, n2, f, m <> path, 0, S.sr.count(res), c0)},
        Cut{}, False{}, True{}, True{}, b, cp, a0, a1, a2, lf, path, m, res, c0)
    case _ 1n+fq KGot{t} _ _ _ _:
      # cut (or no moves left below): the next move
      +mn = U32.add(m, 1)
      +res2 = S.sr.count(res)
      kd.go(d, fq, KTry{t}, Cut{}, False{}, kd.more(mn, res2), S.sr.allowed(mn, lf), b, cp, a0, a1, a2, lf, path, mn, res2, c0)
    case _ 1n+fq KBack{r} _ _ _ _:
      (t, +res2) = r
      +mn = U32.add(m, 1)
      kd.go(d, fq, KTry{t}, Cut{}, False{}, kd.more(mn, res2), S.sr.allowed(mn, lf), b, cp, a0, a1, a2, lf, path, mn, res2, c0)

# A node of cube c (c0 the root, path the moves from it, last first)
type Nd is Data:
  Nd{+cp: U32, +a0: Ax, +a1: Ax, +a2: Ax}

def kd.nd.c(r: Array<U32> & Ax, +cp: U32, +a0: Ax, +a1: Ax) -> Array<U32> & Nd:
  (t, +a2) = r
  (t, Nd{cp, a0, a1, a2})

def kd.nd.b(r: Array<U32> & Ax, +cp: U32, +a0: Ax, +c2: C.Cube, +home: U32) -> Array<U32> & Nd:
  (t, +a1) = r
  kd.nd.c(kd.ax(t, c2, home), cp, a0, a1)

def kd.nd.a(r: Array<U32> & Ax, +cp: U32, +c1: C.Cube, +home: U32) -> Array<U32> & Nd:
  (t, +a0) = r
  kd.nd.b(kd.ax(t, c1, home), cp, a0, Y.sy.conj(c1, Y.sy.URF3()), home)

def kd.nd.k(t: Array<U32>, +k: K.Coords, +c: C.Cube, +home: U32) -> Array<U32> & Nd:
  match k:
    case K.Coords{+cp, tw, a, fa, b, fb}:
      kd.nd.a(kd.ax(t, c, home), cp, Y.sy.conj(c, Y.sy.URF3()), home)

def kd.nd(t: Array<U32>, +c: C.Cube) -> Array<U32> & Nd:
  kd.nd.k(t, K.co.of(c), c, kd.home())

def kd.ax.d(+a: Ax) -> U32:
  match a:
    case Ax{f, u, tw, +d}:
      d

def kd.ax.tw(+a: Ax) -> U32:
  match a:
    case Ax{f, u, +tw, d}:
      tw

# the node's bound: the largest of its four (and 1 if they are all 0 but
# the cube is not solved: a cube no table tells from solved)
def kd.h.cw(r: Array<U32> & U32, +a0: Ax, +a1: Ax, +a2: Ax, +ci: U32, +solved: Bool) -> Array<U32> & U32:
  (t, +w) = r
  +h = U32.max(K.co.nib(w, ci), U32.max(kd.ax.d(a0), U32.max(kd.ax.d(a1), kd.ax.d(a2))))
  (t, Bool.pick(U32, solved, 0, U32.max(h, 1)))

def kd.h.nd(r: Array<U32> & Nd, +solved: Bool) -> Array<U32> & U32:
  (t, n) = r
  match n:
    case Nd{+cp, +a0, +a1, +a2}:
      +ci = U32.add(U32.mul(cp, 2187), kd.ax.tw(a0))
      kd.h.cw(t[U32.add(kd.PC(), U32.shrn(ci, 3n))], a0, a1, a2, ci, solved)

def kd.h(t: Array<U32>, +c: C.Cube) -> Array<U32> & U32:
  kd.h.nd(kd.nd(t, c), C.cube.is_solved(c))

# every sequence of d moves from cube c (reached from c0 by path, last
# first; lf its last face)
def kd.below.nd(r: Array<U32> & Nd, +d: Nat, +lf: U32, +path: List<&2, U32>, +c0: C.Cube) -> Array<U32> & S.Res:
  (t, n) = r
  match n:
    case Nd{+cp, +a0, +a1, +a2}:
      kd.go(d, 255n, KTry{t}, Cut{}, False{}, True{}, S.sr.allowed(0, lf), U32.from_nat(d), cp, a0, a1, a2, lf, path, 0, S.Res{None{}, 0}, c0)

def kd.below(+d: Nat, t: Array<U32>, +c: C.Cube, +lf: U32, +path: List<&2, U32>, +c0: C.Cube) -> Array<U32> & S.Res:
  kd.below.nd(kd.nd(t, c), d, lf, path, c0)

# A node moved by m: its exact distances follow from its own (no bound: b 255)
def kd.walk.kid(r: Array<U32> & Kid, +n: Nd) -> Array<U32> & Nd:
  (t, k) = r
  match k:
    case Cut{}:
      (t, n)
    case Kid{+cp, +a0, +a1, +a2, z}:
      (t, Nd{cp, a0, a1, a2})

def kd.walk.one(r: Array<U32> & Nd, +m: U32) -> Array<U32> & Nd:
  (t, +n) = r
  match n:
    case Nd{+cp, +a0, +a1, +a2}:
      kd.walk.kid(kd.kid(t, 255, cp, a0, a1, a2, m), Nd{cp, a0, a1, a2})

# the node the moves ps (first first) reach from node r's
def kd.walk(ps: List<&2, U32>, r: Array<U32> & Nd) -> Array<U32> & Nd:
  match ps:
    case Nil{}:
      r
    case Con{+m, rest}:
      kd.walk(rest, kd.walk.one(r, m))

# every sequence of d moves from the node the moves ps reach from root node
# n (of cube c0): a subtree of a bound, without the root's distances found
# again (a device's worker keeps the root's node for the cube's jobs)
def kd.below.at(+d: Nat, t: Array<U32>, +n: Nd, +lf: U32, +ps: List<&2, U32>, +c0: C.Cube) -> Array<U32> & S.Res:
  kd.below.nd(kd.walk(ps, (t, n)), d, lf, List.reverse(&2, U32, ps), c0)

# For LAWS.bend (fst_step, fst_rank)
# ----------------------------------

# kd.step undoes each neighbour's residue at distance d: d + 1, d, d - 1
def kd.step.ok(+d: U32) -> Bool:
  Bool.and(Bool.and(U32.is_eq(kd.step(d, U32.mod(U32.add(d, 1), 3)), U32.add(d, 1)), U32.is_eq(kd.step(d, U32.mod(d, 3)), d)),
    Bool.or(U32.is_zero(d), U32.is_eq(kd.step(d, U32.mod(U32.add(d, 2), 3)), U32.sub(d, 1))))

# for every distance below n
def kd.step.all(+n: Nat) -> Bool:
  match n:
    case 0n:
      True{}
    case 1n+p:
      Bool.and(kd.step.ok(U32.from_nat(p)), kd.step.all(p))

# the masks x .. x + n - 1 that have 4 of their 12 bits set (sets of 4
# places) are ranked c, c + 1, ..: each by how many such masks are smaller,
# its place in Lite.bend's list (lt.masks: the 495, in increasing order)
def kd.rank.from(+n: Nat, +x: U32, +c: U32) -> Bool:
  match n:
    case 0n:
      True{}
    case 1n+p:
      +four = U32.is_eq(L.lt.bits(12n, x), 4)
      Bool.and(Bool.or(Bool.not(four), U32.is_eq(kd.rank(x), c)), kd.rank.from(p, U32.add(x, 1), U32.add(c, Bool.to_u32(four))))
