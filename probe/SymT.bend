import Base
import ../Cube.bend as C
import ../Coord.bend as K
import ../Sym.bend as Y

# Probe of Sym.bend: each symmetry's turned moves (18: not a move), the
# eight turns distinct, raw round trips, the solved raw.

def t.row(n: Nat, +s: U32, +m: U32) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Y.sy.cm.n(m, s) <> t.row(p, s, U32.add(m, 1))

def t.urow(n: Nat, +m: U32) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Y.sy.cmu(m) <> t.urow(p, U32.add(m, 1))

def t.rows(n: Nat, +s: U32) -> String:
  match n:
    case 0n:
      ""
    case 1n+p:
      "sym " ++ U32.show(s) ++ ": " ++ C.cube.nums(t.row(18n, s, 0)) ++ "\n" ++ t.rows(p, U32.add(s, 1))

# how many pairs of the eight turns are equal (0 if distinct)
def t.same.go(n: Nat, +s: U32, +u: U32) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      U32.add(Bool.to_u32(Bool.and(U32.is_lt(s, u), C.cube.eq(Y.sy.sym.n(s), Y.sy.sym.n(u)))), t.same.go(p, s, U32.add(u, 1)))

def t.same(n: Nat, +s: U32) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      U32.add(t.same.go(8n, s, 0), t.same(p, U32.add(s, 1)))

# raws r, r + k, .. whose round trip fails
def t.trip(n: Nat, +r: U32, +k: U32) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      U32.add(Bool.to_u32(U32.is_ne(Y.sy.raw(Y.sy.ecube(r)), r)), t.trip(p, U32.add(r, k), k))

def t.tc(n: Nat, +t: U32, +s: U32) -> List<&2, U32>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Y.sy.twist.conj(t, s) <> t.tc(p, t, U32.add(s, 1))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(t.rows(8n, 0))
    IO.print("urf3: " ++ C.cube.nums(t.urow(18n, 0)))
    IO.print("urf3^3 solved: " ++ Bool.pick(String, C.cube.is_solved(C.cube.pow(Y.sy.URF3(), 3n)), "yes", "NO"))
    IO.print("U4^4 solved: " ++ Bool.pick(String, C.cube.is_solved(C.cube.pow(Y.sy.U4(), 4n)), "yes", "NO"))
    IO.print("F2^2 solved: " ++ Bool.pick(String, C.cube.is_solved(C.cube.pow(Y.sy.F2(), 2n)), "yes", "NO"))
    IO.print("equal pairs of turns: " ++ U32.show(t.same(8n, 0)))
    IO.print("solved raw: " ++ U32.show(Y.sy.raw(C.cube.solved())))
    IO.print("raw round trips failed: " ++ U32.show(t.trip(2000n, 7, 12161)))
    IO.print("twist 1234 turned: " ++ C.cube.nums(t.tc(8n, 1234, 0)))
    IO.print("solved raw turned: " ++ U32.show(Y.sy.raw.conj(17858560, 1)) ++ " " ++ U32.show(Y.sy.raw.conj(17858560, 5)))
