import Base
import ./Cube.bend as C
import ./Kd.bend as D
import ./Lite.bend as L

# The device's flip, slice and twist table (Kd.bend), made once and written
# to a file:
#
#   fst-tables <file>
#
# the device array's words kd.P .. kd.end (the distances mod 3, the
# classes, the twists turned, URF3's moves), little-endian. Kd.bend's small
# tables and classes, then its distances at 4 bits breadth first, each level
# on eight lanes that share the one array (handles to one array, so
# @unsafe: this file is built, not checked; Kd.bend's code is checked), then
# packed at 2 bits. The number of classes is printed (kd.cap at most).
#
# Every def is prefixed `ft.`.

# Writing: words k .. k + n as bytes, little-endian (acc holds what follows)
def ft.bytes.w(r: Array<U32> & U32, acc: List<&2, U32>) -> Array<U32> & List<&2, U32>:
  (t, +w) = r
  (t, U32.and(w, 255) <> U32.and(U32.shrn(w, 8n), 255) <> U32.and(U32.shrn(w, 16n), 255) <> U32.shrn(w, 24n) <> acc)

def ft.bytes(n: Nat, r: Array<U32> & List<&2, U32>, +k: U32) -> Array<U32> & List<&2, U32>:
  match n:
    case 0n:
      r
    case 1n++p:
      (t, acc) = r
      ft.bytes(p, ft.bytes.w(t[U32.add(k, U32.from_nat(p))], acc), k)

def ft.chunk() -> U32:
  1048576

# m: the last write; tb: the array and the bytes to write next, of the words
# before k; more: whether there are any
@unsafe
def ft.write(more: Bool, m: File & Result<&1, &1, U32 & String, Unit>, tb: Array<U32> & List<&2, U32>, +k: U32, +end: U32) -> IO(File & Array<U32>):
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
          +n = U32.min(ft.chunk(), U32.sub(end, k))
          do IO<File & Array<U32>>:
            m2 : File & Result<&1, &1, U32 & String, Unit> <- File.write_bytes(f, bs)
            ft.write(U32.is_lt(k, end), m2, ft.bytes(U32.to_nat(n), (t, Nil{}), k), U32.add(k, n), end)
        case Fail{e}:
          IO.die(File & Array<U32>, 1, "could not write the tables")

def ft.close(r: File & Array<U32>) -> IO(Array<U32>):
  (f, t) = r
  do IO<Array<U32>>:
    File.close(f)
    return t

# words k .. end of t to the file at path
@unsafe
def ft.save(+path: String, t: Array<U32>, +k: U32, +end: U32) -> IO(Array<U32>):
  do IO<Array<U32>>:
    f : File <- IO.try(File, File.open(path, "w"))
    m : File & Result<&1, &1, U32 & String, Unit> <- File.write_bytes(f, Nil{})
    r : File & Array<U32> <- ft.write(True{}, m, (t, Nil{}), k, end)
    ft.close(r)

def ft.ms(+t0: Nat, +t1: Nat) -> String:
  Nat.show(Nat.sub(t1, t0)) ++ " ms"

def ft.join(x: Array<U32> & U32, y: Array<U32> & U32) -> Array<U32> & U32:
  (a, +p) = x
  (b, +q) = y
  (Array.join(U32, a, b), U32.add(p, q))

# a level over words k .. k + n, on 2^d lanes
@unsafe
def ft.lanes(+d: Nat, +t: Array<U32>, +k: U32, +n: U32, +lv: U32, +back: Bool) -> Array<U32> & U32:
  match d:
    case 0n:
      D.kd.level(U32.to_nat(n), (t, 0), k, lv, back)
    case 1n+p:
      +h = U32.shrn(n, 1n)
      x y = ft.lanes(p, t, k, h, lv, back) ft.lanes(p, t, U32.add(k, h), U32.sub(n, h), lv, back)
      ft.join(x, y)

# The levels (Build.bend's bd.levels): seen, total: half the entries found
# so far and of all; backward once fewer are unseen than the level found
@unsafe
def ft.levels(k: Nat, r: Array<U32> & U32, +d: U32, +seen: U32, +total: U32, +words: U32, +a: Nat, +back: Bool) -> IO(Array<U32>):
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
        IO.print("level " ++ U32.show(d) ++ ": " ++ U32.show(n) ++ Bool.pick(String, back, " (backward)", " (forward)") ++ ", " ++ ft.ms(a, b))
        ft.levels(Bool.pick(Nat, U32.is_zero(n), 0n, p), ft.lanes(3n, t, 0, words, d, back2), U32.add(d, 1), seen2, total, words, b, back2)

@unsafe
def ft.classes(r: Array<U32> & U32, +path: String, +t0: Nat) -> IO(Unit):
  (t, +nc) = r
  +words = U32.mul(nc, 274)
  +packed = U32.shrn(U32.add(U32.mul(nc, 2187), 15), 4n)
  do IO<Unit>:
    +t1 : Nat <- IO.now()
    IO.print("classes: " ++ U32.show(nc) ++ " (room for " ++ U32.show(D.kd.cap()) ++ "), " ++ ft.ms(t0, t1))
    t2 : Array<U32> <- ft.levels(16n, D.kd.seed(t), 0, 0, U32.add(U32.mul(nc, 1093), U32.shrn(nc, 1n)), words, t1, False{})
    +t3 : Nat <- IO.now()
    IO.print("distances: " ++ ft.ms(t1, t3) ++ "; packed words: " ++ U32.show(packed))
    t4 : Array<U32> <- ft.save(path, D.kd.pack(U32.to_nat(packed), t2, 0), D.kd.P(), D.kd.end())
    +t5 : Nat <- IO.now()
    IO.print("written to " ++ path ++ ", " ++ ft.ms(t3, t5))

def ft.path(xs: List<String>) -> String:
  match xs:
    case Con{a, Con{b, t}}:
      b
    case _:
      "fst.bin"

@unsafe
def ft.start(+path: String, t: Array<U32>, +t0: Nat) -> IO(Unit):
  do IO<Unit>:
    +t1 : Nat <- IO.now()
    IO.print("small tables: " ++ ft.ms(t0, t1))
    ft.classes(D.kd.classes(D.kd.nraw(), (t, 0), L.lt.masks(), 0), path, t1)

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    +t0 : Nat <- IO.now()
    ft.start(ft.path(args), D.kd.small([4294967295 : U32^27n]), t0)
