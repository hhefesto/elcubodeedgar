import Base
import ../Cube.bend as C
import ../Guard.bend as Gd

# Probe: Guard.bend on many cubes. n random scrambles (30 moves each, from
# Marsaglia's xorshift32): each must read back as itself; each with one
# corner twisted, one edge flipped, two corners or two edges swapped, or one
# sticker painted another color must be refused. Prints the counts, and one
# reason of each kind.
#
#   guardt [n]

def gt.next(+x: U32) -> U32:
  +a = U32.xor(x, U32.shln(x, 13n))
  +b = U32.xor(a, U32.shrn(a, 17n))
  U32.xor(b, U32.shln(b, 5n))

def gt.moves(n: Nat, +x: U32) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+q:
      U32.mod(U32.shrn(gt.next(x), 5n), 18) <> gt.moves(q, gt.next(x))

def gt.set(+xs: List<&2, U32>, +i: U32, +v: U32) -> List<&2, U32>:
  List.set(&2, U32, xs, U32.to_nat(i), v)

def gt.get(+xs: List<&2, U32>, +i: U32) -> U32:
  Maybe.default(&2, U32, List.get(&2, U32, xs, U32.to_nat(i)), 0)

def gt.swap(+xs: List<&2, U32>, +i: U32, +j: U32) -> List<&2, U32>:
  gt.set(gt.set(xs, i, gt.get(xs, j)), j, gt.get(xs, i))

# the cube c spoiled: kind 0 a corner twisted, 1 an edge flipped, 2 two
# corners swapped, 3 two edges swapped (at places from x)
def gt.spoil(+c: C.Cube, +k: U32, +x: U32) -> C.Cube:
  match c:
    case C.Cube{+cp, +co, +ep, +eo}:
      +p = U32.mod(x, 8)
      +q = U32.mod(U32.add(p, U32.add(1, U32.mod(U32.shrn(x, 8n), 7))), 8)
      +e = U32.mod(x, 12)
      +f = U32.mod(U32.add(e, U32.add(1, U32.mod(U32.shrn(x, 8n), 11))), 12)
      Bool.pick(C.Cube, U32.is_eq(k, 0), C.Cube{cp, gt.set(co, p, U32.mod(U32.add(gt.get(co, p), 1), 3)), ep, eo},
        Bool.pick(C.Cube, U32.is_eq(k, 1), C.Cube{cp, co, ep, gt.set(eo, e, U32.xor(gt.get(eo, e), 1))},
          Bool.pick(C.Cube, U32.is_eq(k, 2), C.Cube{gt.swap(cp, p, q), co, ep, eo}, C.Cube{cp, co, gt.swap(ep, e, f), eo})))

def gt.cube(+r: Gd.Read) -> C.Cube:
  match r:
    case Gd.Good{+c}:
      c
    case Gd.Bad{w}:
      C.cube.solved()

# counts: [good and equal, kind 0 refused, 1, 2, 3, a sticker repainted refused]
def gt.tally(+c: C.Cube, +x: U32) -> List<&2, U32>:
  +back = Gd.gd.check(Gd.gd.of(c))
  +s = U32.mod(U32.shrn(x, 3n), 54)
  +cols = Gd.gd.of(c)
  +painted = gt.set(cols, s, U32.mod(U32.add(gt.get(cols, s), U32.add(1, U32.mod(x, 5))), 6))
  [Bool.to_u32(Bool.and(Gd.gd.ok(back), C.cube.eq(c, gt.cube(back)))),
   Bool.to_u32(Bool.not(Gd.gd.ok(Gd.gd.check(Gd.gd.of(gt.spoil(c, 0, x)))))),
   Bool.to_u32(Bool.not(Gd.gd.ok(Gd.gd.check(Gd.gd.of(gt.spoil(c, 1, x)))))),
   Bool.to_u32(Bool.not(Gd.gd.ok(Gd.gd.check(Gd.gd.of(gt.spoil(c, 2, x)))))),
   Bool.to_u32(Bool.not(Gd.gd.ok(Gd.gd.check(Gd.gd.of(gt.spoil(c, 3, x)))))),
   Bool.to_u32(Bool.not(Gd.gd.ok(Gd.gd.check(painted))))]

def gt.add(xs: List<&2, U32>, ys: List<&2, U32>) -> List<&2, U32>:
  match xs ys:
    case Con{+a, t} Con{+b, u}:
      U32.add(a, b) <> gt.add(t, u)
    case _ _:
      Nil{}

def gt.run(n: Nat, +x: U32, acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      acc
    case 1n+q:
      +c = C.cube.apply(gt.moves(30n, x), C.cube.solved())
      gt.run(q, gt.next(gt.next(x)), gt.add(acc, gt.tally(c, gt.next(x))))

def gt.n(xs: List<String>) -> Nat:
  match xs:
    case Con{a, Con{b, t}}:
      U32.to_nat(Maybe.default(&2, U32, U32.read(b), 1000))
    case _:
      1000n

def gt.report(+n: Nat) -> IO(Unit):
  +c = C.cube.apply(gt.moves(30n, 7), C.cube.solved())
  +r = gt.run(n, 12345, [0, 0, 0, 0, 0, 0])
  do IO<Unit>:
    IO.print("cubes: " ++ Nat.show(n) ++ "; read back as themselves, a twisted corner refused, a flipped edge, two corners swapped, two edges swapped, a sticker repainted: " ++ C.cube.nums(r))
    IO.print("twisted: " ++ Gd.gd.why(Gd.gd.check(Gd.gd.of(gt.spoil(c, 0, 5)))))
    IO.print("flipped: " ++ Gd.gd.why(Gd.gd.check(Gd.gd.of(gt.spoil(c, 1, 5)))))
    IO.print("corners swapped: " ++ Gd.gd.why(Gd.gd.check(Gd.gd.of(gt.spoil(c, 2, 5)))))
    IO.print("edges swapped: " ++ Gd.gd.why(Gd.gd.check(Gd.gd.of(gt.spoil(c, 3, 5)))))
    IO.print("repainted: " ++ Gd.gd.why(Gd.gd.check(gt.set(Gd.gd.of(c), 0, U32.mod(U32.add(gt.get(Gd.gd.of(c), 0), 1), 6)))))
    IO.print("two stickers of two faces swapped: " ++ Gd.gd.why(Gd.gd.check(gt.swap(Gd.gd.of(c), 0, 9))))
    IO.print("solved: " ++ Bool.pick(String, Gd.gd.ok(Gd.gd.read(C.cube.facelets(C.cube.solved()))), "good", "BAD"))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    gt.report(gt.n(args))
