import Base
import ../Ways.bend as W
import ../Cube.bend as C

# Ways.bend on n random 25-move scrambles (xorshift32 from a seed): how many
# ways reached the goal of every step and solved the cube ("ok"), of 3n, and
# each way's moves in all. Built, not interpreted (`bend` runs main slowly):
#
#   bend probe/WaysT.bend -o /tmp/wayst && /tmp/wayst
#
# 11-16, 200 scrambles: 600 of 600 ok; CFOP 52.3 moves on average, with a
# four-look last layer 66.0, the beginner's 134.1.

def rnd(+x: U32) -> U32:
  +a = U32.xor(x, U32.shln(x, 13n))
  +b = U32.xor(a, U32.shrn(a, 17n))
  U32.xor(b, U32.shln(b, 5n))

def scr(n: Nat, +x: U32, +acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      acc
    case 1n+p:
      +y = rnd(x)
      scr(p, y, U32.mod(U32.shrn(y, 7n), 18) <> acc)

# A tally: ways ok, and each way's moves (1, 2, 3)
type Ty is Data:
  Ty{+ok: U32, +m1: U32, +m2: U32, +m3: U32}

def moves(+s: String) -> U32:
  Bool.pick(U32, String.is_empty(s), 0, U32.from_nat(List.length(&2, String, String.split(s, '.'))))

def field(+l: String, +i: Nat) -> String:
  Maybe.default(&2, String, List.get(&2, String, String.split(l, '|'), i), "")

# the lines of one scramble's answer, w the way they are under
def tally(ls: List<&2, String>, +w: U32, +t: Ty) -> Ty:
  match ls:
    case Nil{}:
      t
    case Con{+l, rest}:
      match t:
        case Ty{+ok, +m1, +m2, +m3}:
          +isw = String.starts_with(l, "W|")
          +n = Bool.pick(U32, isw, 0, moves(field(l, 2n)))
          +w2 = Bool.pick(U32, isw, Maybe.default(&2, U32, U32.read(field(l, 1n)), 0), w)
          tally(rest, w2, Ty{U32.add(ok, Bool.pick(U32, Bool.and(isw, String.eq(field(l, 2n), "ok")), 1, 0)),
            U32.add(m1, Bool.pick(U32, U32.is_eq(w2, 1), n, 0)), U32.add(m2, Bool.pick(U32, U32.is_eq(w2, 2), n, 0)),
            U32.add(m3, Bool.pick(U32, U32.is_eq(w2, 3), n, 0))})

def add(r: Array<U32> & String, +t: Ty) -> Array<U32> & Ty:
  (a, +s) = r
  (a, tally(String.split(s, '\n'), 0, t))

def go(n: Nat, r: Array<U32> & Ty, +x: U32) -> Array<U32> & Ty:
  match n:
    case 0n:
      r
    case 1n+p:
      (a, +t) = r
      +y = rnd(rnd(x))
      go(p, add(W.wy.run(a, W.wy.simp(scr(25n, y, []))), t), y)

# a total over n, to a tenth: "52.3"
def avg(+m: U32, +n: U32) -> String:
  +t = U32.div(U32.add(U32.mul(m, 10), U32.shrn(n, 1n)), n)
  U32.show(U32.div(t, 10)) ++ "." ++ U32.show(U32.mod(t, 10))

def fin(r: Array<U32> & Ty, +n: U32) -> String:
  (a, +t) = r
  match t:
    case Ty{+ok, +m1, +m2, +m3}:
      U32.show(ok) ++ " of " ++ U32.show(U32.mul(n, 3)) ++ " ok; moves on average: CFOP " ++ avg(m1, n)
        ++ ", four-look " ++ avg(m2, n) ++ ", beginner's " ++ avg(m3, n)

def main() -> String:
  fin(go(200n, (W.wy.tables(), Ty{0, 0, 0, 0}), 12345), 200)
