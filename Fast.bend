import Base
import ./Cube.bend as C
import ./Search.bend as S
import ./Solve.bend as V
import ./Opt.bend as O

# The faster solver on every core: Opt.bend's search, with the tables read
# from the file Build.bend wrote, and its rounds on eight lanes that share
# the one array (handles to it: so @unsafe, and this file is built, not
# checked; Opt.bend's search is checked).
#
# A solve: the cube's distance bound is the first bound; each bound below 9
# is searched on one lane, from 9 on on eight (each with an eighth of the
# canonical three-move prefixes), until a bound has a solution: a shortest
# one (Opt.bend). Bounds stop at 20 (every cube is at most 20 moves from
# solved: Rokicki, Kociemba, Davidson, Dethridge, 2010).
#
# Every def is prefixed `fs.`.

def fs.join(x: Array<U32> & S.Res, y: Array<U32> & S.Res) -> Array<U32> & S.Res:
  (a, rx) = x
  (b, ry) = y
  (Array.join(U32, a, b), O.op.pick(rx, ry))

# every lane at once, each with its prefixes, all reading t
@unsafe
def fs.go(+t: Array<U32>, w: O.W, +b: U32) -> Array<U32> & S.Res:
  match w:
    case O.WLeaf{ps}:
      O.op.lane(ps, (t, S.Res{None{}, 0}), b)
    case O.WNode{l, r}:
      x y = fs.go(t, l, b) fs.go(t, r, b)
      fs.join(x, y)

# bound b: on one lane below 9, on eight from 9
@unsafe
def fs.round(t: Array<U32>, +b: U32, +n: O.Node, +ps: List<&2, O.Pre>, par: Bool) -> Array<U32> & S.Res:
  match par:
    case True{}:
      fs.go(t, O.op.deal(2n, ps), b)
    case False{}:
      O.op.below(U32.to_nat(b), t, n, 6, Nil{})

# after bound b's round: its solution, or the next bound (k bounds left)
@unsafe
def fs.next(k: Nat, r: Array<U32> & S.Res, +b: U32, +tot: U32, +n: O.Node, +ps: List<&2, O.Pre>) -> Array<U32> & V.Ans:
  match k:
    case 0n:
      (t, res) = r
      match res:
        case S.Res{f, c}:
          (t, V.Ans{f, U32.add(tot, c), b})
    case 1n+q:
      (t, res) = r
      match res:
        case S.Res{f, c}:
          match f:
            case Some{ms}:
              (t, V.Ans{Some{ms}, U32.add(tot, c), b})
            case None{}:
              +b1 = U32.add(b, 1)
              fs.next(q, fs.round(t, b1, n, ps, U32.is_ge(b1, 9)), b1, U32.add(tot, c), n, ps)

@unsafe
def fs.start.go(zero: Bool, t: Array<U32>, +h: U32, +n: O.Node, +v: O.View) -> Array<U32> & V.Ans:
  match zero:
    case True{}:
      (t, V.Ans{Some{Nil{}}, 0, 0})
    case False{}:
      +ps = O.op.prefixes(3n, v)
      fs.next(U32.to_nat(U32.sub(20, h)), fs.round(t, h, n, ps, U32.is_ge(h, 9)), h, 0, n, ps)

@unsafe
def fs.start(r: Array<U32> & U32, +n: O.Node, +v: O.View) -> Array<U32> & V.Ans:
  (t, +h) = r
  fs.start.go(U32.is_zero(h), t, h, n, v)

# A shortest solution of the cube the moves ms make from solved
@unsafe
def fs.solve(t: Array<U32>, +ms: List<&2, U32>) -> Array<U32> & V.Ans:
  +v = O.op.view(ms)
  +n = O.op.view.node(v)
  fs.start(O.op.bound(t, n), n, v)

# A solve in steps, for a server
# ------------------------------
#
# The same search, a step at a time: a bound below 9 in one step, one lane;
# from 9, a chunk of fs.per(b) prefixes a step, on eight lanes. Between steps
# the solve gives the event loop a turn (a 3 ms sleep), so the server answers
# others, and looks at the clock: past the limit it stops and says so.

# a solve's answer, and whether it ran out of time
type Out is Data:
  Out{+ans: V.Ans, +late: Bool}

# a step's result, and the prefixes of its bound still to search
type Step is Type:
  Step{r: Array<U32> & S.Res, +rest: List<&2, O.Pre>}

type Ph is Data:
  PGo{}
  PLate{}
  POver{}

# prefixes a step: fewer as bounds deepen, so a step stays short
def fs.per(+b: U32) -> Nat:
  Bool.pick(Nat, U32.is_le(b, 14), 256n, Bool.pick(Nat, U32.is_eq(b, 15), 96n, Bool.pick(Nat, U32.is_eq(b, 16), 32n, 8n)))

def fs.empty(+xs: List<&2, O.Pre>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case Con{x, t}:
      False{}

def fs.take(k: Nat, xs: List<&2, O.Pre>, acc: List<&2, O.Pre>) -> List<&2, O.Pre> & List<&2, O.Pre>:
  match k xs:
    case 1n+q Con{+x, t}:
      fs.take(q, t, x <> acc)
    case _ _:
      (List.reverse(&2, O.Pre, acc), xs)

@unsafe
def fs.chunk.go(t: Array<U32>, r: List<&2, O.Pre> & List<&2, O.Pre>, +b: U32) -> Step:
  (ch, rest) = r
  Step{fs.go(t, O.op.deal(2n, ch), b), rest}

# bound b's next step: all of it (below 9), its next chunk (9 to 20), or
# nothing (past 20)
@unsafe
def fs.work.go(par: Bool, over: Bool, t: Array<U32>, +b: U32, +rest: List<&2, O.Pre>, +n: O.Node) -> Step:
  match par over:
    case _ True{}:
      Step{(t, S.Res{None{}, 0}), Nil{}}
    case False{} False{}:
      Step{O.op.below(U32.to_nat(b), t, n, 6, Nil{}), Nil{}}
    case True{} False{}:
      fs.chunk.go(t, fs.take(fs.per(b), rest, Nil{}), b)

@unsafe
def fs.work(t: Array<U32>, +b: U32, +rest: List<&2, O.Pre>, +n: O.Node) -> Step:
  fs.work.go(U32.is_ge(b, 9), U32.is_gt(b, 20), t, b, rest, n)

def fs.phase(+now: Nat, +t0: Nat, +limit: Nat, +b: U32) -> Ph:
  Bool.pick(Ph, U32.is_gt(b, 20), POver{}, Bool.pick(Ph, Nat.is_gt(Nat.sub(now, t0), limit), PLate{}, PGo{}))

# st: the last step's result, of bound b; tot: the nodes before it
@unsafe
def fs.io.go(k: Nat, ph: Ph, st: Step, +b: U32, +tot: U32, +n: O.Node, +ps: List<&2, O.Pre>, +t0: Nat, +limit: Nat) -> IO(Array<U32> & Out):
  match k ph:
    case 0n _:
      match st:
        case Step{r, rest}:
          (t, res) = r
          IO.pure(Array<U32> & Out, (t, Out{V.Ans{None{}, tot, b}, True{}}))
    case 1n+q PLate{}:
      match st:
        case Step{r, rest}:
          (t, res) = r
          IO.pure(Array<U32> & Out, (t, Out{V.Ans{None{}, tot, b}, True{}}))
    case 1n+q POver{}:
      match st:
        case Step{r, rest}:
          (t, res) = r
          IO.pure(Array<U32> & Out, (t, Out{V.Ans{None{}, tot, b}, False{}}))
    case 1n+q PGo{}:
      match st:
        case Step{r, +rest}:
          (t, res) = r
          match res:
            case S.Res{f, +c}:
              match f:
                case Some{+xs}:
                  IO.pure(Array<U32> & Out, (t, Out{V.Ans{Some{xs}, U32.add(tot, c), b}, False{}}))
                case None{}:
                  +done = fs.empty(rest)
                  +nb = Bool.pick(U32, done, U32.add(b, 1), b)
                  st2 = fs.work(t, nb, Bool.pick(List<&2, O.Pre>, done, ps, rest), n)
                  do IO<Array<U32> & Out>:
                    IO.sleep(3)
                    +now : Nat <- IO.now()
                    fs.io.go(q, fs.phase(now, t0, limit, nb), st2, nb, U32.add(tot, c), n, ps, t0, limit)

# A shortest solution of the cube the moves ms make, or none if limit
# milliseconds pass first
@unsafe
def fs.solve.io.go(zero: Bool, t: Array<U32>, +h: U32, +n: O.Node, +v: O.View, +t0: Nat, +limit: Nat) -> IO(Array<U32> & Out):
  match zero:
    case True{}:
      IO.pure(Array<U32> & Out, (t, Out{V.Ans{Some{Nil{}}, 0, 0}, False{}}))
    case False{}:
      fs.io.go(100000n, PGo{}, Step{(t, S.Res{None{}, 0}), Nil{}}, U32.sub(h, 1), 0, n, O.op.prefixes(3n, v), t0, limit)

@unsafe
def fs.solve.io.start(r: Array<U32> & U32, +n: O.Node, +v: O.View, +t0: Nat, +limit: Nat) -> IO(Array<U32> & Out):
  (t, +h) = r
  fs.solve.io.go(U32.is_zero(h), t, h, n, v, t0, limit)

@unsafe
def fs.solve.io(t: Array<U32>, +ms: List<&2, U32>, +limit: Nat) -> IO(Array<U32> & Out):
  +v = O.op.view(ms)
  +n = O.op.view.node(v)
  do IO<Array<U32> & Out>:
    +t0 : Nat <- IO.now()
    fs.solve.io.start(O.op.bound(t, n), n, v, t0, limit)

# Reading the tables
# ------------------

# bytes, little-endian, as words from k on
def fs.fill(bs: List<&2, U32>, t: Array<U32>, +k: U32) -> Array<U32>:
  match bs:
    case Con{+a, Con{+b, Con{+c, Con{+d, rest}}}}:
      +w = U32.or(U32.or(a, U32.shln(b, 8n)), U32.or(U32.shln(c, 16n), U32.shln(d, 24n)))
      fs.fill(rest, Array.set(U32, t, k, w), U32.add(k, 1))
    case _:
      t

def fs.chunk() -> U32:
  1048576

# m: the last read, of n words from k; end: the file's words
@unsafe
def fs.read(more: Bool, m: File & Result<&1, &1, U32 & String, List<&2, U32>>, t: Array<U32>, +k: U32, +n: U32, +end: U32) -> IO(Array<U32>):
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
          t2 = fs.fill(bs, t, k)
          +k2 = U32.add(k, n)
          +n2 = U32.min(fs.chunk(), U32.sub(end, k2))
          do IO<Array<U32>>:
            m2 : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at(f, U32.mul(k2, 4), U32.mul(n2, 4))
            fs.read(U32.is_lt(k2, end), m2, t2, k2, n2, end)
        case Fail{e}:
          IO.die(Array<U32>, 1, "could not read the tables")

def fs.size(m: File & Result<&1, &1, U32 & String, U32>) -> IO(File & U32):
  (f, r) = m
  match r:
    case Done{+s}:
      IO.pure(File & U32, (f, s))
    case Fail{e}:
      IO.die(File & U32, 1, "could not size the tables")

@unsafe
def fs.load.go(fs2: File & U32) -> IO(Array<U32>):
  (f, +bytes) = fs2
  +end = U32.shrn(bytes, 2n)
  +n = U32.min(fs.chunk(), end)
  do IO<Array<U32>>:
    m : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at(f, 0, U32.mul(n, 4))
    fs.read(True{}, m, [0 : U32^30n], 0, n, end)

# the tables, from the file at path
@unsafe
def fs.load(+path: String) -> IO(Array<U32>):
  do IO<Array<U32>>:
    f : File <- IO.try(File, File.open(path, "r"))
    m : File & Result<&1, &1, U32 & String, U32> <- File.size(f)
    fs2 : File & U32 <- fs.size(m)
    fs.load.go(fs2)
