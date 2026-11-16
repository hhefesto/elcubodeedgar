import Base
import ../Cube.bend as C
import ../Coord.bend as K
import ../Solve.bend as V
import ../Par.bend as P

# Probe: how long Coord.bend's tables take to build where Bend runs as
# JavaScript (bun, node): its move tables, then each distance table
#
#   bun moves.js

def mv.ms(+a: Nat, +b: Nat) -> String:
  Nat.show(Nat.sub(b, a)) ++ " ms"

@unsafe
def mv.dist(t: Array<U32>, +t0: Nat) -> IO(Unit):
  +s = K.co.of(C.cube.solved())
  t1 = V.sv.seed(V.sv.seed(V.sv.seed(t, K.co.T.pc(), 0), K.co.T.pa(), P.pl.ea(s)), K.co.T.pb(), P.pl.eb(s))
  do IO<Unit>:
    t2 : Array<U32> <- IO.pure(Array<U32>, V.sv.levels(12n, (t1, 0), K.KE{K.co.T.pa()}, 0))
    +a : Nat <- IO.now()
    IO.print("one table of six edges (42,577,920 entries): " ++ mv.ms(t0, a))
    t3 : Array<U32> <- IO.pure(Array<U32>, V.sv.levels(12n, (t2, 0), K.KC{}, 0))
    +b : Nat <- IO.now()
    IO.print("the corners (88,179,840 entries): " ++ mv.ms(a, b))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    +t0 : Nat <- IO.now()
    t : Array<U32> <- IO.pure(Array<U32>, K.co.moves.fill([4294967295 : U32^26n]))
    +t1 : Nat <- IO.now()
    IO.print("move tables (corners' permutations and twists, six edges' arrangements): " ++ mv.ms(t0, t1))
    mv.dist(t, t1)
