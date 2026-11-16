import Base
import ../Cube.bend as C
import ../Coord.bend as K
import ../Search.bend as S
import ../Par.bend as P

def p.levels(n: Nat, r: Array<U32> & U32, +k: K.Tab, +d: U32, acc: List<&2, U32>) -> Array<U32> & List<&2, U32>:
  match n:
    case 0n:
      (t, v) = r
      (t, acc)
    case 1n+q:
      (t, +c) = r
      p.levels(q, K.co.level(t, k, d), k, U32.add(d, 1), c <> acc)

def p.show(xs: List<&2, U32>) -> String:
  match xs:
    case Nil{}:
      ""
    case Con{+x, t}:
      p.show(t) ++ " " ++ U32.show(x)

def p.seed(t: Array<U32>, +off: U32, +i: U32) -> Array<U32>:
  Array.set(U32, t, U32.add(off, U32.shrn(i, 3n)), K.co.lower.w(4294967295, i, 0))

def p.ea(+c: K.Coords) -> U32:
  match c:
    case K.Coords{cp, tw, a, fa, b, fb}:
      U32.add(U32.shln(a, 6n), fa)

def p.eb(+c: K.Coords) -> U32:
  match c:
    case K.Coords{cp, tw, a, fa, b, fb}:
      U32.add(U32.shln(b, 6n), fb)

def p.cp(+c: K.Coords) -> U32:
  match c:
    case K.Coords{cp, tw, a, fa, b, fb}:
      cp

def p.tw(+c: K.Coords) -> U32:
  match c:
    case K.Coords{cp, tw, a, fa, b, fb}:
      tw

def p.fst(r: Array<U32> & List<&2, U32>) -> Array<U32>:
  (t, xs) = r
  t

# every table
def p.tables() -> Array<U32>:
  +s = K.co.of(C.cube.solved())
  t0 = K.co.moves.fill([4294967295 : U32^26n])
  t1 = p.seed(p.seed(p.seed(t0, K.co.T.pc(), 0), K.co.T.pa(), p.ea(s)), K.co.T.pb(), p.eb(s))
  t2 = p.fst(p.levels(12n, (t1, 0), K.KC{}, 0, Nil{}))
  t3 = p.fst(p.levels(12n, (t2, 0), K.KE{K.co.T.pa()}, 0, Nil{}))
  p.fst(p.levels(12n, (t3, 0), K.KE{K.co.T.pb()}, 0, Nil{}))

def q.ploop(n: Nat, r: P.Ts & S.Res, +b: U32, +ps: List<&2, P.Pre>, +t0: Nat) -> IO(Unit):
  match n:
    case 0n:
      IO.print("no solution within 20")
    case 1n+q:
      (ts, res) = r
      match res:
        case S.Res{f, nodes}:
          match f:
            case Some{ms}:
              do IO<Unit>:
                +t1 : Nat <- IO.now()
                IO.print("bound " ++ U32.show(b) ++ " (8 lanes): " ++ U32.show(nodes) ++ " nodes, " ++ Nat.show(Nat.sub(t1, t0)) ++ " ms: " ++ C.cube.show(ms))
            case None{}:
              do IO<Unit>:
                +t1 : Nat <- IO.now()
                IO.print("bound " ++ U32.show(b) ++ " (8 lanes): " ++ U32.show(nodes) ++ " nodes, " ++ Nat.show(Nat.sub(t1, t0)) ++ " ms")
                q.ploop(q, P.pl.go(ts, P.pl.deal(ps), U32.add(b, 1)), U32.add(b, 1), ps, t1)

def q.sloop(n: Nat, par: Bool, r: Array<U32> & S.Res, +b: U32, +c: K.Coords, +cube: C.Cube, +t0: Nat) -> IO(Unit):
  match n par:
    case 0n _:
      IO.print("no solution within 20")
    case 1n+q True{}:
      # from here on, every lane
      (t, res) = r
      do IO<Unit>:
        +t1 : Nat <- IO.now()
        IO.print("eight lanes from bound " ++ U32.show(b))
        q.ploop(21n, P.pl.go(P.pl.lanes(t), P.pl.deal(P.pl.prefixes(3n, cube)), b), b, P.pl.prefixes(3n, cube), t1)
    case 1n+q False{}:
      (t, res) = r
      match res:
        case S.Res{f, nodes}:
          match f:
            case Some{ms}:
              do IO<Unit>:
                +t1 : Nat <- IO.now()
                IO.print("bound " ++ U32.show(b) ++ ": " ++ U32.show(nodes) ++ " nodes, " ++ Nat.show(Nat.sub(t1, t0)) ++ " ms: " ++ C.cube.show(ms))
            case None{}:
              do IO<Unit>:
                +t1 : Nat <- IO.now()
                IO.print("bound " ++ U32.show(b) ++ ": " ++ U32.show(nodes) ++ " nodes, " ++ Nat.show(Nat.sub(t1, t0)) ++ " ms")
                q.sloop(q, U32.is_ge(U32.add(b, 1), 9), S.sr.below(U32.to_nat(U32.add(b, 1)), t, p.cp(c), p.tw(c), p.ea(c), p.eb(c), 6, Nil{}), U32.add(b, 1), c, cube, t1)

def q.start(r: Array<U32> & U32, +c: K.Coords, +cube: C.Cube, +t0: Nat) -> IO(Unit):
  (t, +h) = r
  do IO<Unit>:
    IO.print("distance bound " ++ U32.show(h))
    q.sloop(21n, False{}, S.sr.below(U32.to_nat(h), t, p.cp(c), p.tw(c), p.ea(c), p.eb(c), 6, Nil{}), h, c, cube, t0)

def q.go(m: Maybe<&2, List<&2, U32>>, t: Array<U32>, +t0: Nat) -> IO(Unit):
  match m:
    case None{}:
      IO.print("not moves")
    case Some{+ms}:
      +cube = C.cube.apply(ms, C.cube.solved())
      +c = K.co.of(cube)
      do IO<Unit>:
        IO.print("scramble " ++ C.cube.show(ms))
        q.start(S.sr.h(t, p.cp(c), p.tw(c), p.ea(c), p.eb(c)), c, cube, t0)

def q.arg(xs: List<String>) -> String:
  match xs:
    case Con{x, Con{y, t}}:
      y
    case _:
      ""

def main() -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    tab : Array<U32> = p.tables()
    +t1 : Nat <- IO.now()
    IO.print("tables: " ++ Nat.show(Nat.sub(t1, t0)) ++ " ms")
    args : List<String> <- IO.args()
    q.go(C.cube.parse(q.arg(args)), tab, t1)
