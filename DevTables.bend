import Base
import ./Cube.bend as C
import ./Coord.bend as K
import ./Par.bend as P
import ./Solve.bend as V
import ./Lite.bend as L

# The device's downloaded tables (Dev.bend), made once and written to two
# files:
#
#   dev-tables <korf file> <lite file>
#
#   korf: words 13107200 .. 34774160 of the device's array: Coord.bend's
#         three distance tables (the corners; two sets of six edges), 4 bits
#         an entry: what Korf's search needs, 86.7 MB (about 22 MB brotli)
#   lite: words 35000000 .. lt.end(): Lite.bend's two-phase tables
#         (18 MB, mostly zeros' worth of small numbers)
# little-endian. The device makes Coord.bend's move tables itself (they are
# bigger than they are slow to make: the edges' 48 MB, 29 MB brotli).
#
# IO and a loop over the file, so built, not checked; the tables' code is
# Coord.bend's, Solve.bend's and Lite.bend's, checked.
#
# Every def is prefixed `dt.`.

# Writing: words k .. k + n as bytes, little-endian (acc holds what follows)
def dt.bytes.w(r: Array<U32> & U32, acc: List<&2, U32>) -> Array<U32> & List<&2, U32>:
  (t, +w) = r
  (t, U32.and(w, 255) <> U32.and(U32.shrn(w, 8n), 255) <> U32.and(U32.shrn(w, 16n), 255) <> U32.shrn(w, 24n) <> acc)

def dt.bytes(n: Nat, r: Array<U32> & List<&2, U32>, +k: U32) -> Array<U32> & List<&2, U32>:
  match n:
    case 0n:
      r
    case 1n++p:
      (t, acc) = r
      dt.bytes(p, dt.bytes.w(t[U32.add(k, U32.from_nat(p))], acc), k)

def dt.chunk() -> U32:
  1048576

# m: the last write; tb: the array and the bytes to write next, of the words
# before k; more: whether there are any
@unsafe
def dt.write(more: Bool, m: File & Result<&1, &1, U32 & String, Unit>, tb: Array<U32> & List<&2, U32>, +k: U32, +end: U32) -> IO(File & Array<U32>):
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
          +n = U32.min(dt.chunk(), U32.sub(end, k))
          do IO<File & Array<U32>>:
            m2 : File & Result<&1, &1, U32 & String, Unit> <- File.write_bytes(f, bs)
            dt.write(U32.is_lt(k, end), m2, dt.bytes(U32.to_nat(n), (t, Nil{}), k), U32.add(k, n), end)
        case Fail{e}:
          IO.die(File & Array<U32>, 1, "could not write the tables")

def dt.close(r: File & Array<U32>) -> IO(Array<U32>):
  (f, t) = r
  do IO<Array<U32>>:
    File.close(f)
    return t

# words k .. end of t to the file at path
@unsafe
def dt.save(+path: String, t: Array<U32>, +k: U32, +end: U32) -> IO(Array<U32>):
  do IO<Array<U32>>:
    f : File <- IO.try(File, File.open(path, "w"))
    m : File & Result<&1, &1, U32 & String, Unit> <- File.write_bytes(f, Nil{})
    r : File & Array<U32> <- dt.write(True{}, m, (t, Nil{}), k, end)
    dt.close(r)

def dt.ms(+t0: Nat, +t1: Nat) -> String:
  Nat.show(Nat.sub(t1, t0)) ++ " ms"

# Coord.bend's tables, as Solve.bend's sv.tables makes them
def dt.coord(t0: Array<U32>) -> Array<U32>:
  +s = K.co.of(C.cube.solved())
  t1 = K.co.moves.fill(t0)
  t2 = V.sv.seed(V.sv.seed(V.sv.seed(t1, K.co.T.pc(), 0), K.co.T.pa(), P.pl.ea(s)), K.co.T.pb(), P.pl.eb(s))
  t3 = V.sv.levels(12n, (t2, 0), K.KC{}, 0)
  t4 = V.sv.levels(12n, (t3, 0), K.KE{K.co.T.pa()}, 0)
  V.sv.levels(12n, (t4, 0), K.KE{K.co.T.pb()}, 0)

type Args is Data:
  Args{+korf: String, +lite: String}

def dt.args(xs: List<String>) -> Args:
  match xs:
    case Con{a, Con{b, Con{c, t}}}:
      Args{b, c}
    case _:
      Args{"korf.bin", "lite.bin"}

@unsafe
def dt.go(a: Args, t: Array<U32>, +t0: Nat) -> IO(Unit):
  match a:
    case Args{+korf, +lite}:
      do IO<Unit>:
        +t1 : Nat <- IO.now()
        IO.print("tables made in " ++ dt.ms(t0, t1))
        t2 : Array<U32> <- dt.save(korf, t, K.co.T.pc(), 34774160)
        t3 : Array<U32> <- dt.save(lite, t2, L.lt.FM(), L.lt.end())
        +t4 : Nat <- IO.now()
        IO.print("written to " ++ korf ++ " and " ++ lite ++ " in " ++ dt.ms(t1, t4))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    +t0 : Nat <- IO.now()
    dt.go(dt.args(args), L.lt.all(dt.coord([4294967295 : U32^26n])), t0)
