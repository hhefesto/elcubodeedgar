import Base
import ../Cube.bend as C
import ../Coord.bend as K
import ../Search.bend as S
import ../Par.bend as P

# Probe: the first solver (Coord.bend's three tables, Search.bend's IDA*) on
# one lane, for Bend's JavaScript target: is solving on a visitor's device
# fast enough? The tables (Coord.bend's 2^26 words) are read from the first
# 256 MiB of Build.bend's file.
#
#   node jssolve.js <tables> <scramble> ..

def js.fill(bs: List<&2, U32>, t: Array<U32>, +k: U32) -> Array<U32>:
  match bs:
    case Con{+a, Con{+b, Con{+c, Con{+d, rest}}}}:
      +w = U32.or(U32.or(a, U32.shln(b, 8n)), U32.or(U32.shln(c, 16n), U32.shln(d, 24n)))
      js.fill(rest, Array.set(U32, t, k, w), U32.add(k, 1))
    case _:
      t

@unsafe
def js.read(more: Bool, m: File & Result<&1, &1, U32 & String, List<&2, U32>>, t: Array<U32>, +k: U32, +n: U32) -> IO(Array<U32>):
  match more:
    case False{}:
      (f, r) = m
      do IO<Array<U32>>:
        File.close(f)
        return t
    case True{}:
      (f, r) = m
      match r:
        case Done{bs}:
          t2 = js.fill(bs, t, k)
          +k2 = U32.add(k, n)
          do IO<Array<U32>>:
            m2 : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at(f, U32.mul(k2, 4), U32.mul(n, 4))
            js.read(U32.is_lt(k2, 67108864), m2, t2, k2, n)
        case Fail{e}:
          IO.die(Array<U32>, 1, "could not read the tables")

@unsafe
def js.load(+path: String) -> IO(Array<U32>):
  do IO<Array<U32>>:
    f : File <- IO.try(File, File.open(path, "r"))
    m : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at(f, 0, 4194304)
    js.read(True{}, m, [0 : U32^26n], 0, 1048576)

# bounds from b on, one lane, until one has a solution (k bounds at most)
def js.ida(k: Nat, r: Array<U32> & S.Res, +b: U32, +c: K.Coords) -> Array<U32> & S.Res:
  match k:
    case 0n:
      r
    case 1n+q:
      (t, res) = r
      match res:
        case S.Res{Some{+ms}, n}:
          (t, S.Res{Some{ms}, n})
        case S.Res{None{}, n}:
          js.ida(q, S.sr.below(U32.to_nat(b), t, P.pl.cp(c), P.pl.tw(c), P.pl.ea(c), P.pl.eb(c), 6, Nil{}), U32.add(b, 1), c)

def js.say(+ms: List<&2, U32>, +res: S.Res, +dt: Nat) -> String:
  match res:
    case S.Res{Some{+sol}, k}:
      +ok = C.cube.is_solved(C.cube.apply(sol, C.cube.apply(ms, C.cube.solved())))
      U32.show(U32.from_nat(List.length(&2, U32, ms))) ++ " moves -> " ++ C.cube.show(sol) ++ " | " ++ U32.show(k) ++ " nodes, " ++ Nat.show(dt) ++ " ms, " ++ Bool.pick(String, ok, "ok", "WRONG")
    case S.Res{None{}, k}:
      "none | " ++ U32.show(k) ++ " nodes, " ++ Nat.show(dt) ++ " ms"

@unsafe
def js.one(r: Array<U32> & S.Res, +ms: List<&2, U32>, +t0: Nat) -> IO(Array<U32>):
  (t, res) = r
  do IO<Array<U32>>:
    +t1 : Nat <- IO.now()
    IO.print(js.say(ms, res, Nat.sub(t1, t0)))
    return t

@unsafe
def js.all(xs: List<String>, t: Array<U32>) -> IO(Unit):
  match xs:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case Con{x, rest}:
      +ms = Maybe.default(&2, List<&2, U32>, C.cube.read(x), Nil{})
      +c = K.co.of(C.cube.apply(ms, C.cube.solved()))
      do IO<Unit>:
        +t0 : Nat <- IO.now()
        t2 : Array<U32> <- js.one(js.ida(21n, (t, S.Res{None{}, 0}), 0, c), ms, t0)
        js.all(rest, t2)

@unsafe
def js.main(xs: List<String>) -> IO(Unit):
  match xs:
    case Con{a, Con{path, rest}}:
      do IO<Unit>:
        +t0 : Nat <- IO.now()
        t : Array<U32> <- js.load(path)
        +t1 : Nat <- IO.now()
        IO.print("tables read in " ++ Nat.show(Nat.sub(t1, t0)) ++ " ms")
        js.all(rest, t)
    case _:
      IO.print("jssolve <tables> <scramble> ..")

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    js.main(args)
