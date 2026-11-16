import Base
import ../Cube.bend as C
import ../Opt.bend as O
import ../Fast.bend as F
import ../TwoPhase.bend as P

# Probe: the two-phase solver (TwoPhase.bend) on scrambles, each answer
# checked: its length, the ways into S tried, the nodes, the milliseconds
#
#   tp <tables> <scramble> ..

def tp.say(+ms: List<&2, U32>, +b: P.Best, +dt: Nat) -> String:
  match b:
    case P.Best{Some{+sol}, len, tries, nodes}:
      +ok = C.cube.is_solved(C.cube.apply(sol, C.cube.apply(ms, C.cube.solved())))
      U32.show(P.tp.len(ms)) ++ " moves -> " ++ U32.show(len) ++ ": " ++ C.cube.show(sol) ++ " | " ++ U32.show(tries) ++ " tries, " ++ U32.show(nodes) ++ " nodes, " ++ Nat.show(dt) ++ " ms, " ++ Bool.pick(String, ok, "ok", "WRONG")
    case P.Best{None{}, len, tries, nodes}:
      U32.show(P.tp.len(ms)) ++ " moves -> none | " ++ U32.show(tries) ++ " tries, " ++ U32.show(nodes) ++ " nodes, " ++ Nat.show(dt) ++ " ms"

def tp.node(t: Array<U32>, +n: O.Node, +c0: C.Cube) -> Array<U32> & P.Best:
  match n:
    case O.Node{cp, t0, r0, t1, r1, t2, r2}:
      P.tp.solve(t, t0, r0, c0)

def tp.run(t: Array<U32>, +ms: List<&2, U32>) -> Array<U32> & P.Best:
  tp.node(t, O.op.view.node(O.op.view(ms)), C.cube.apply(ms, C.cube.solved()))

@unsafe
def tp.one(r: Array<U32> & P.Best, +ms: List<&2, U32>, +t0: Nat) -> IO(Array<U32>):
  (t, +b) = r
  do IO<Array<U32>>:
    +t1 : Nat <- IO.now()
    IO.print(tp.say(ms, b, Nat.sub(t1, t0)))
    return t

@unsafe
def tp.all(xs: List<String>, t: Array<U32>) -> IO(Unit):
  match xs:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case Con{x, rest}:
      +ms = Maybe.default(&2, List<&2, U32>, C.cube.read(x), Nil{})
      do IO<Unit>:
        +t0 : Nat <- IO.now()
        t2 : Array<U32> <- tp.one(tp.run(t, ms), ms, t0)
        tp.all(rest, t2)

@unsafe
def tp.main(xs: List<String>) -> IO(Unit):
  match xs:
    case Con{a, Con{path, rest}}:
      do IO<Unit>:
        t : Array<U32> <- F.fs.load(path)
        +t0 : Nat <- IO.now()
        t2 : Array<U32> <- IO.pure(Array<U32>, P.tp.tables(t))
        +t1 : Nat <- IO.now()
        IO.print("two-phase tables made in " ++ Nat.show(Nat.sub(t1, t0)) ++ " ms")
        tp.all(rest, t2)
    case _:
      IO.print("tp <tables> <scramble> ..")

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    tp.main(args)
