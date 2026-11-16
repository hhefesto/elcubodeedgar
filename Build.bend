import Base
import ./Cube.bend as C
import ./Coord.bend as K
import ./Sym.bend as Y
import ./Kc.bend as T
import ./Par.bend as P
import ./Solve.bend as V

# The faster solver's tables, built and written to a file:
#
#   build-tables <file>
#
# Coord.bend's moves and exact tables, Kc.bend's small tables and classes,
# then Kc.bend's distances breadth first, each level on eight lanes that
# share the one array (handles to one array, so @unsafe: this file is built,
# not checked; Kc.bend's levels are checked). The file is the array's words
# 0 .. kc.P + classes * 274, little-endian; the number of classes is at word
# bd.META.
#
# Every def is prefixed `bd.`.

def bd.META() -> U32:
  35600000

def bd.join(x: Array<U32> & U32, y: Array<U32> & U32) -> Array<U32> & U32:
  (a, +p) = x
  (b, +q) = y
  (Array.join(U32, a, b), U32.add(p, q))

# a level over words k .. k + n, on 2^d lanes
@unsafe
def bd.lanes(+d: Nat, +t: Array<U32>, +k: U32, +n: U32, +lv: U32, +back: Bool) -> Array<U32> & U32:
  match d:
    case 0n:
      T.kc.level(U32.to_nat(n), (t, 0), k, lv, back)
    case 1n+p:
      +h = U32.shrn(n, 1n)
      x y = bd.lanes(p, t, k, h, lv, back) bd.lanes(p, t, U32.add(k, h), U32.sub(n, h), lv, back)
      bd.join(x, y)

# Coord.bend's tables, in the array's first 2^26 words (Solve.bend's sv.tables)
def bd.coord(t0: Array<U32>) -> Array<U32>:
  +s = K.co.of(C.cube.solved())
  t1 = K.co.moves.fill(t0)
  t2 = V.sv.seed(V.sv.seed(V.sv.seed(t1, K.co.T.pc(), 0), K.co.T.pa(), P.pl.ea(s)), K.co.T.pb(), P.pl.eb(s))
  t3 = V.sv.levels(12n, (t2, 0), K.KC{}, 0)
  t4 = V.sv.levels(12n, (t3, 0), K.KE{K.co.T.pa()}, 0)
  V.sv.levels(12n, (t4, 0), K.KE{K.co.T.pb()}, 0)

def bd.ms(+t0: Nat, +t1: Nat) -> String:
  Nat.show(Nat.sub(t1, t0)) ++ " ms"

# The levels. r: the array and level d's count, just found (it began at a,
# backward if back). seen: half the entries found so far, total: half of
# all (counts pass U32's range). The next level goes backward once fewer
# are unseen than level d has; none are left to find once a level finds none.
@unsafe
def bd.levels(k: Nat, r: Array<U32> & U32, +d: U32, +seen: U32, +total: U32, +words: U32, +a: Nat, +back: Bool) -> IO(Array<U32>):
  match k:
    case 0n:
      (t, n) = r
      IO.pure(Array<U32>, t)
    case 1n+p:
      (t, +n) = r
      +seen2 = U32.add(seen, U32.shrn(n, 1n))
      +back2 = U32.is_lt(U32.sub(total, U32.min(seen2, total)), U32.shrn(n, 1n))
      do IO<Array<U32>>:
        +b : Nat <- IO.now()
        IO.print("level " ++ U32.show(d) ++ ": " ++ U32.show(n) ++ Bool.pick(String, back, " (backward)", " (forward)") ++ ", " ++ bd.ms(a, b))
        bd.levels(Bool.pick(Nat, U32.is_zero(n), 0n, p), bd.lanes(3n, t, 0, words, d, back2), U32.add(d, 1), seen2, total, words, b, back2)

# Writing: words k .. k + n as bytes, little-endian (acc holds what follows)
def bd.bytes.w(r: Array<U32> & U32, acc: List<&2, U32>) -> Array<U32> & List<&2, U32>:
  (t, +w) = r
  (t, U32.and(w, 255) <> U32.and(U32.shrn(w, 8n), 255) <> U32.and(U32.shrn(w, 16n), 255) <> U32.shrn(w, 24n) <> acc)

def bd.bytes(n: Nat, r: Array<U32> & List<&2, U32>, +k: U32) -> Array<U32> & List<&2, U32>:
  match n:
    case 0n:
      r
    case 1n++p:
      (t, acc) = r
      bd.bytes(p, bd.bytes.w(t[U32.add(k, U32.from_nat(p))], acc), k)

def bd.chunk() -> U32:
  1048576

# m: the last write; tb: the array and the bytes to write next, of the words
# before k; more: whether there are any
@unsafe
def bd.write(more: Bool, m: File & Result<&1, &1, U32 & String, Unit>, tb: Array<U32> & List<&2, U32>, +k: U32, +end: U32) -> IO(File & Array<U32>):
  match more:
    case False{}:
      (f, r) = m
      match r:
        case Done{u}:
          (t, bs) = tb
          IO.pure(File & Array<U32>, (f, t))
        case Fail{e}:
          IO.die(File & Array<U32>, 1, "could not write the tables")
    case True{}:
      (f, r) = m
      match r:
        case Done{u}:
          (t, bs) = tb
          +n = U32.min(bd.chunk(), U32.sub(end, k))
          do IO<File & Array<U32>>:
            m2 : File & Result<&1, &1, U32 & String, Unit> <- File.write_bytes(f, bs)
            bd.write(U32.is_lt(k, end), m2, bd.bytes(U32.to_nat(n), (t, Nil{}), k), U32.add(k, n), end)
        case Fail{e}:
          IO.die(File & Array<U32>, 1, "could not write the tables")

def bd.close(r: File & Array<U32>) -> IO(Unit):
  (f, t) = r
  File.close(f)

@unsafe
def bd.save(+path: String, t: Array<U32>, +end: U32) -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open(path, "w"))
    m : File & Result<&1, &1, U32 & String, Unit> <- File.write_bytes(f, Nil{})
    r : File & Array<U32> <- bd.write(True{}, m, (t, Nil{}), 0, end)
    bd.close(r)

@unsafe
def bd.classes(r: Array<U32> & U32, +path: String, +t0: Nat) -> IO(Unit):
  (t, +nc) = r
  +words = U32.mul(nc, 274)
  do IO<Unit>:
    +t1 : Nat <- IO.now()
    IO.print("classes: " ++ U32.show(nc) ++ ", " ++ bd.ms(t0, t1))
    t2 : Array<U32> <- bd.levels(16n, T.kc.seed(Array.set(U32, t, bd.META(), nc)), 0, 0, U32.add(U32.mul(nc, 1093), U32.shrn(nc, 1n)), words, t1, False{})
    +t3 : Nat <- IO.now()
    IO.print("distances: " ++ bd.ms(t1, t3))
    bd.save(path, t2, U32.add(T.kc.P(), words))
    +t4 : Nat <- IO.now()
    IO.print("written to " ++ path ++ ", " ++ bd.ms(t3, t4))

def bd.path(xs: List<String>) -> String:
  match xs:
    case Con{a, Con{b, t}}:
      b
    case _:
      "tables.bin"

@unsafe
def bd.start(+path: String, t: Array<U32>, +t0: Nat) -> IO(Unit):
  do IO<Unit>:
    +t1 : Nat <- IO.now()
    IO.print("moves, corners, edges, small tables: " ++ bd.ms(t0, t1))
    bd.classes(T.kc.classes(T.kc.nraw(), (t, 0), 0), path, t1)

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    +t0 : Nat <- IO.now()
    bd.start(bd.path(args), T.kc.small(bd.coord([4294967295 : U32^30n])), t0)
