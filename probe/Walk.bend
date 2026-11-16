import Base
import ../Cube.bend as C
import ../Search.bend as S
import ../Opt.bend as O
import ../Fast.bend as F

# Probe: along a known solution, each step's child through op.kid with the
# bound the moves left give: it must be a node (or solved, at the end)
#
#   walk <tables> <scramble> <solution>

def w.kind(+k: O.Kid) -> String:
  match k:
    case O.KCut{}:
      "CUT"
    case O.KGoal{}:
      "goal"
    case O.KNode{cp, t0, r0, t1, r1, t2, r2}:
      "node"

def w.step(r: Array<U32> & O.Kid, +acc: String) -> Array<U32> & String:
  (t, +k) = r
  (t, acc ++ " " ++ w.kind(k))

def w.kid(t: Array<U32>, +n: O.Node, +m: U32, +bud: U32, +acc: String) -> Array<U32> & String:
  match n:
    case O.Node{cp, t0, r0, t1, r1, t2, r2}:
      w.step(O.op.kid(t, cp, t0, r0, t1, r1, t2, r2, m, bud), acc)

# each move of the solution from the cube the moves done make
def w.go(sol: List<&2, U32>, r: Array<U32> & String, +done: List<&2, U32>, +left: U32) -> Array<U32> & String:
  match sol:
    case Nil{}:
      r
    case Con{+m, rest}:
      (t, +acc) = r
      +n = O.op.view.node(O.op.view(done))
      w.go(rest, w.kid(t, n, m, left, acc), List.append(&2, U32, done, [m]), U32.sub(left, 1))


def w.len(xs: List<&2, U32>) -> U32:
  match xs:
    case Nil{}:
      0
    case Con{x, t}:
      U32.add(w.len(t), 1)

@unsafe
def w.say(r: Array<U32> & String) -> IO(Unit):
  (t, s) = r
  IO.print(s)

@unsafe
def w.main(xs: List<String>) -> IO(Unit):
  match xs:
    case Con{a, Con{path, Con{s, Con{z, rest}}}}:
      +ms = Maybe.default(&2, List<&2, U32>, C.cube.read(s), Nil{})
      +sol = Maybe.default(&2, List<&2, U32>, C.cube.read(z), Nil{})
      do IO<Unit>:
        t : Array<U32> <- F.fs.load(path)
        w.say(w.go(sol, (t, "steps:"), ms, w.len(sol)))
    case _:
      IO.print("walk <tables> <scramble> <solution>")

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    w.main(args)
