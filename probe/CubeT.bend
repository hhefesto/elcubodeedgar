import Base
import ../Cube.bend as C

def t.show(m: Maybe<&2, List<&2, U32>>) -> String:
  match m:
    case None{}:
      "bad"
    case Some{+ms}:
      C.cube.show(ms) ++ " | " ++ C.cube.facelets(C.cube.apply(ms, C.cube.solved())) ++ " | undone " ++ Bool.show(C.cube.is_solved(C.cube.apply(C.cube.inv(ms), C.cube.apply(ms, C.cube.solved()))))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(C.cube.facelets(C.cube.solved()))
    IO.print(t.show(C.cube.parse("R")))
    IO.print(t.show(C.cube.parse("U")))
    IO.print(t.show(C.cube.parse("F")))
    IO.print(t.show(C.cube.parse("R U R' U'")))
    IO.print(t.show(C.cube.parse("R R R R")))
    IO.print(t.show(C.cube.parse("R2 x")))
    IO.print(t.show(C.cube.parse("D2 L' B, F2  U")))
