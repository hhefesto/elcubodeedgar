import Base
import ../Cube.bend as C

# Each move's name and the stickers it leaves on a solved cube, one per line,
# then two sequences: for probe/turns.mjs to hold the 3D view's turns to.
def f.line(+m: U32) -> String:
  C.cube.name(m) ++ " " ++ C.cube.facelets(C.cube.move(m))

def f.lines(n: Nat, +m: U32) -> String:
  match n:
    case 0n:
      ""
    case 1n+q:
      f.line(m) ++ "\n" ++ f.lines(q, U32.add(m, 1))

def f.seq(+s: String) -> String:
  s ++ "|" ++ C.cube.facelets(C.cube.apply(Maybe.default(&2, List<&2, U32>, C.cube.parse(s), []), C.cube.solved()))

def main() -> IO(Unit):
  IO.print(f.lines(18n, 0) ++ f.seq("R U R' U'") ++ "\n" ++ f.seq("F2 L' D B U2 R F' L2") ++ "\n" ++ f.seq(""))
