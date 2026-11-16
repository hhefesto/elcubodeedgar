import Base
import ./Cube.bend as C
import ./Search.bend as S
import ./Solve.bend as V
import ./Opt.bend as O
import ./Fast.bend as F

# The solver, as a process of its own (the page's server, Server.bend, sends
# it the cubes, and kills it if it ever holds one past the hard limit):
#
#   cube-solver <port> <tables>
#
# reads the tables (Build.bend's file, about 40 s), then answers on
# 127.0.0.1:<port> (not before: so a server asks a standby meanwhile):
#   GET /health              "ok", from the computation that takes
#                            connections, so only if the event loop turns
#   GET /solve?v=V&m=3.10.17 a shortest solution of the cube the moves make,
#                            for visitor V (any name, or none)
#
# One computation solves, one cube at a time, on every core (Fast.bend's
# search, a chunk of prefixes a step, a 3 ms sleep between steps so the
# rest runs). Between steps it takes the cubes that came in: a visitor's new
# cube cancels the one of theirs being solved or waiting; past wk.cap()
# waiting, a cube is turned away. A solve stops after wk.limit() ms, and an
# asker waits at most wk.wait() ms (the server, Server.bend, kills this
# process if even that does not come: then its event loop is stuck).
#
# The answer is four lines: the moves ("" for none, or one word: "late" if
# the time ran out, "busy" if too many wait, "cancelled" if the visitor
# asked for another, "none" if no solution within 20), the nodes, the
# milliseconds, and "ok" when the scramble then the solution leaves the cube
# solved (checked here by Cube.bend; the page checks it again). A word has a
# fifth line: the bound being searched (every shorter one was searched in
# full, so the shortest solution has at least that many moves).
#
# Every def is prefixed `wk.`.

def wk.limit() -> Nat:
  75000n

def wk.wait() -> U32:
  85000

def wk.cap() -> U32:
  6

# A request: who, the moves, where the answer goes
type Req is Data:
  Req{+vis: String, +ms: List<&2, U32>, +reply: Chan(String)}

# what a step found waiting: carry on, stop (time, or past 20), or cancel
type WPh is Data:
  WGo{}
  WLate{}
  WOver{}
  WCancel{}

type WS is Data:
  WS{+ph: WPh, +news: List<&2, Req>}

# a solve's end: its answer, how it ended, the requests that came meanwhile
type Fin is Data:
  Fin{+ans: V.Ans, +how: WPh, +news: List<&2, Req>}

def wk.same(+a: String, +b: String) -> Bool:
  Bool.and(Bool.not(String.is_empty(a)), String.eq(a, b))

def wk.base(+now: Nat, +t0: Nat, +limit: Nat, +b: U32) -> WPh:
  Bool.pick(WPh, U32.is_gt(b, 20), WOver{}, Bool.pick(WPh, Nat.is_gt(Nat.sub(now, t0), limit), WLate{}, WGo{}))

# the step's phase, given what came in (p) for this solve's visitor
def wk.ph(p: Poll<&1, &1, Maybe<&1, Req>, Unit>, +vis: String, +now: Nat, +t0: Nat, +limit: Nat, +b: U32, +news: List<&2, Req>) -> WS:
  match p:
    case Ready{Some{+r}}:
      match r:
        case Req{+v, +ms, +reply}:
          WS{Bool.pick(WPh, wk.same(v, vis), WCancel{}, wk.base(now, t0, limit, b)), List.append(&2, Req, news, [r])}
    case _:
      WS{wk.base(now, t0, limit, b), news}

# the prefixes, made the first time a bound needs them (from 9 on): a cube
# solved in fewer moves never pays for them
def wk.pre(need: Bool, +ps: List<&2, O.Pre>, +v: O.View) -> List<&2, O.Pre>:
  match need:
    case True{}:
      O.op.prefixes(3n, v)
    case False{}:
      ps

# Fast.bend's fs.io.go, taking in requests between steps
@unsafe
def wk.run(k: Nat, ws: WS, st: F.Step, +b: U32, +tot: U32, +n: O.Node, +v: O.View, +ps: List<&2, O.Pre>, +t0: Nat, +limit: Nat, +jobs: Chan(Req), +vis: String) -> IO(Array<U32> & Fin):
  match k ws:
    case 0n WS{ph, +news}:
      match st:
        case F.Step{r, rest}:
          (t, res) = r
          IO.pure(Array<U32> & Fin, (t, Fin{V.Ans{None{}, tot, b}, WLate{}, news}))
    case 1n+q WS{WLate{}, +news}:
      match st:
        case F.Step{r, rest}:
          (t, res) = r
          IO.pure(Array<U32> & Fin, (t, Fin{V.Ans{None{}, tot, b}, WLate{}, news}))
    case 1n+q WS{WOver{}, +news}:
      match st:
        case F.Step{r, rest}:
          (t, res) = r
          IO.pure(Array<U32> & Fin, (t, Fin{V.Ans{None{}, tot, b}, WOver{}, news}))
    case 1n+q WS{WCancel{}, +news}:
      match st:
        case F.Step{r, rest}:
          (t, res) = r
          IO.pure(Array<U32> & Fin, (t, Fin{V.Ans{None{}, tot, b}, WCancel{}, news}))
    case 1n+q WS{WGo{}, +news}:
      match st:
        case F.Step{r, +rest}:
          (t, res) = r
          match res:
            case S.Res{f, +c}:
              match f:
                case Some{+xs}:
                  IO.pure(Array<U32> & Fin, (t, Fin{V.Ans{Some{xs}, U32.add(tot, c), b}, WGo{}, news}))
                case None{}:
                  +done = F.fs.empty(rest)
                  +nb = Bool.pick(U32, done, U32.add(b, 1), b)
                  +ps2 = wk.pre(Bool.and(U32.is_ge(nb, 9), F.fs.empty(ps)), ps, v)
                  st2 = F.fs.work(t, nb, Bool.pick(List<&2, O.Pre>, done, ps2, rest), n)
                  do IO<Array<U32> & Fin>:
                    IO.sleep(3)
                    +now : Nat <- IO.now()
                    p : Poll<&1, &1, Maybe<&1, Req>, Unit> <- Chan.try_recv(Req, jobs, 0)
                    wk.run(q, wk.ph(p, vis, now, t0, limit, nb, news), st2, nb, U32.add(tot, c), n, v, ps2, t0, limit, jobs, vis)

@unsafe
def wk.start.go(zero: Bool, t: Array<U32>, +h: U32, +n: O.Node, +v: O.View, +t0: Nat, +jobs: Chan(Req), +vis: String) -> IO(Array<U32> & Fin):
  match zero:
    case True{}:
      IO.pure(Array<U32> & Fin, (t, Fin{V.Ans{Some{Nil{}}, 0, 0}, WGo{}, Nil{}}))
    case False{}:
      wk.run(100000n, WS{WGo{}, Nil{}}, F.Step{(t, S.Res{None{}, 0}), Nil{}}, U32.sub(h, 1), 0, n, v, Nil{}, t0, wk.limit(), jobs, vis)

@unsafe
def wk.start(r: Array<U32> & U32, +n: O.Node, +v: O.View, +t0: Nat, +jobs: Chan(Req), +vis: String) -> IO(Array<U32> & Fin):
  (t, +h) = r
  wk.start.go(U32.is_zero(h), t, h, n, v, t0, jobs, vis)

@unsafe
def wk.solve(t: Array<U32>, +ms: List<&2, U32>, +jobs: Chan(Req), +vis: String) -> IO(Array<U32> & Fin):
  +v = O.op.view(ms)
  +n = O.op.view.node(v)
  do IO<Array<U32> & Fin>:
    +t0 : Nat <- IO.now()
    wk.start(O.op.bound(t, n), n, v, t0, jobs, vis)

# Answers
# -------

# a word for an answer without moves, then the nodes, the milliseconds, "ok",
# and the bound being searched (every shorter one was searched in full: the
# shortest solution has at least that many moves)
def wk.word(+w: String, +k: U32, +dt: Nat, +b: U32) -> String:
  w ++ "\n" ++ U32.show(k) ++ "\n" ++ Nat.show(dt) ++ "\nok\n" ++ U32.show(b) ++ "\n"

def wk.body(+ms: List<&2, U32>, d: Fin, +dt: Nat) -> String:
  match d:
    case Fin{V.Ans{Some{+sol}, k, b}, how, news}:
      +ok = C.cube.is_solved(C.cube.apply(sol, C.cube.apply(ms, C.cube.solved())))
      C.cube.nums(sol) ++ "\n" ++ U32.show(k) ++ "\n" ++ Nat.show(dt) ++ "\n" ++ Bool.pick(String, ok, "ok", "WRONG") ++ "\n"
    case Fin{V.Ans{None{}, k, b}, WLate{}, news}:
      wk.word("late", k, dt, b)
    case Fin{V.Ans{None{}, k, b}, WCancel{}, news}:
      wk.word("cancelled", k, dt, b)
    case Fin{V.Ans{None{}, k, b}, how, news}:
      wk.word("none", k, dt, b)

def wk.news(+d: Fin) -> List<&2, Req>:
  match d:
    case Fin{a, h, +news}:
      news

def wk.sent(r: Result<&1, &1, String, Unit>) -> IO(Unit):
  IO.pure(Unit, Unit{})

def wk.say(+reply: Chan(String), +body: String) -> IO(Unit):
  do IO<Unit>:
    r : Result<&1, &1, String, Unit> <- Chan.send(String, reply, body)
    wk.sent(r)

# tell each of rs the word w
@unsafe
def wk.tell(rs: List<&2, Req>, +w: String) -> IO(Unit):
  match rs:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case Con{+r, rest}:
      match r:
        case Req{v, ms, +reply}:
          do IO<Unit>:
            wk.say(reply, wk.word(w, 0, 0n, 0))
            wk.tell(rest, w)

# the queue without the visitor's requests (vis: none, keeps all), and those
def wk.drop(q: List<&2, Req>, +vis: String, +keep: List<&2, Req>, +out: List<&2, Req>) -> List<&2, Req> & List<&2, Req>:
  match q:
    case Nil{}:
      (List.reverse(&2, Req, keep), out)
    case Con{+r, rest}:
      match r:
        case Req{+v, +ms, +reply}:
          +gone = wk.same(v, vis)
          wk.drop(rest, vis, Bool.pick(List<&2, Req>, gone, keep, r <> keep), Bool.pick(List<&2, Req>, gone, r <> out, out))

def wk.len(q: List<&2, Req>) -> U32:
  match q:
    case Nil{}:
      0
    case Con{r, t}:
      U32.add(wk.len(t), 1)

def wk.vis(+r: Req) -> String:
  match r:
    case Req{+v, ms, reply}:
      v

@unsafe
def wk.add.go(full: Bool, s: List<&2, Req> & List<&2, Req>, +r: Req) -> IO(List<&2, Req>):
  match full:
    case True{}:
      (q, gone) = s
      do IO<List<&2, Req>>:
        wk.tell(gone, "cancelled")
        wk.tell([r], "busy")
        return q
    case False{}:
      (q, gone) = s
      do IO<List<&2, Req>>:
        wk.tell(gone, "cancelled")
        return List.append(&2, Req, q, [r])

# r into the queue q: the visitor's older ones cancelled; turned away if full
@unsafe
def wk.add(q: List<&2, Req>, +r: Req) -> IO(List<&2, Req>):
  +s = wk.drop(q, wk.vis(r), Nil{}, Nil{})
  wk.add.go(U32.is_ge(wk.len(Pair.fst(List<&2, Req>, List<&2, Req>, s)), wk.cap()), s, r)

@unsafe
def wk.adds(rs: List<&2, Req>, q: List<&2, Req>) -> IO(List<&2, Req>):
  match rs:
    case Nil{}:
      IO.pure(List<&2, Req>, q)
    case Con{+r, rest}:
      do IO<List<&2, Req>>:
        q2 : List<&2, Req> <- wk.add(q, r)
        wk.adds(rest, q2)

def wk.both(t: Array<U32>, q: List<&2, Req>) -> IO(Array<U32> & List<&2, Req>):
  IO.pure(Array<U32> & List<&2, Req>, (t, q))

# a solve done: the answer to its asker, the cubes that came meanwhile queued
@unsafe
def wk.after(+job: Req, r: Array<U32> & Fin, +rest: List<&2, Req>, +t0: Nat) -> IO(Array<U32> & List<&2, Req>):
  match job:
    case Req{+v, +ms, +reply}:
      (t, +d) = r
      do IO<Array<U32> & List<&2, Req>>:
        +t1 : Nat <- IO.now()
        IO.print("solve " ++ C.cube.nums(ms) ++ " -> " ++ String.join(String.split(wk.body(ms, d, Nat.sub(t1, t0)), '\n'), " "))
        wk.say(reply, wk.body(ms, d, Nat.sub(t1, t0)))
        q : List<&2, Req> <- wk.adds(wk.news(d), rest)
        wk.both(t, q)

@unsafe
def wk.one(t: Array<U32>, +job: Req, +rest: List<&2, Req>, +jobs: Chan(Req)) -> IO(Array<U32> & List<&2, Req>):
  match job:
    case Req{+v, +ms, +reply}:
      do IO<Array<U32> & List<&2, Req>>:
        +t0 : Nat <- IO.now()
        r : Array<U32> & Fin <- wk.solve(t, ms, jobs, v)
        wk.after(job, r, rest, t0)

# the solver: the queue's first solved, then the next; with none, wait for one
@unsafe
def wk.loop(k: Nat, m: Maybe<&1, Req>, s: Array<U32> & List<&2, Req>, +jobs: Chan(Req)) -> IO(Unit):
  match k m:
    case 0n _:
      (t, q) = s
      IO.pure(Unit, Unit{})
    case 1n+p Some{+r}:
      (t, q) = s
      do IO<Unit>:
        q2 : List<&2, Req> <- wk.add(q, r)
        s2 : Array<U32> & List<&2, Req> <- wk.both(t, q2)
        wk.loop(p, None{}, s2, jobs)
    case 1n+p None{}:
      (t, q) = s
      match q:
        case Nil{}:
          do IO<Unit>:
            m2 : Maybe<&1, Req> <- Chan.recv(Req, jobs)
            s2 : Array<U32> & List<&2, Req> <- wk.both(t, Nil{})
            wk.loop(p, m2, s2, jobs)
        case Con{+job, +rest}:
          do IO<Unit>:
            s2 : Array<U32> & List<&2, Req> <- wk.one(t, job, rest, jobs)
            wk.loop(p, None{}, s2, jobs)

# Connections
# -----------

def wk.head(+status: String, +len: Nat) -> String:
  "HTTP/1.1 " ++ status ++ "\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: " ++ Nat.show(len) ++ "\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n"

def wk.sent2(m: Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>) -> IO(Unit):
  (s, r) = m
  Socket.close(s)

def wk.text(s: Socket, +status: String, +body: String) -> IO(Unit):
  do IO<Unit>:
    m : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send(s, wk.head(status, String.length(body)) ++ body)
    wk.sent2(m)

def wk.answer(s: Socket, m: Maybe<&1, Maybe<&1, String>>) -> IO(Unit):
  match m:
    case Some{Some{+body}}:
      wk.text(s, "200 OK", body)
    case _:
      wk.text(s, "200 OK", wk.word("busy", 0, 0n, 0))

def wk.queued(s: Socket, r: Result<&1, &1, Req, Unit>, +reply: Chan(String)) -> IO(Unit):
  match r:
    case Done{u}:
      do IO<Unit>:
        m : Maybe<&1, Maybe<&1, String>> <- IO.within(Maybe<&1, String>, wk.wait(), Chan.recv(String, reply))
        wk.answer(s, m)
    case Fail{j}:
      wk.text(s, "503 Service Unavailable", "the solver is not running\n")

def wk.ask(s: Socket, +jobs: Chan(Req), +vis: String, +ms: List<&2, U32>) -> IO(Unit):
  do IO<Unit>:
    +reply : Chan(String) <- Chan.new(String, 1)
    r : Result<&1, &1, Req, Unit> <- Chan.send(Req, jobs, Req{vis, ms, reply})
    wk.queued(s, r, reply)

def wk.param.go(ps: List<&2, String>, +k: String) -> String:
  match ps:
    case Nil{}:
      ""
    case Con{+p, rest}:
      Bool.pick(String, String.starts_with(p, k ++ "="), String.drop(p, Nat.add(String.length(k), 1n)), wk.param.go(rest, k))

def wk.solve.got(s: Socket, +jobs: Chan(Req), +vis: String, m: Maybe<&2, List<&2, U32>>) -> IO(Unit):
  match m:
    case Some{+ms}:
      wk.ask(s, jobs, vis, ms)
    case None{}:
      wk.text(s, "400 Bad Request", "m: moves 0..17 joined by '.'\n")

# "v=V&m=M": the value of key k ("" if none)
def wk.param(+q: String, +k: String) -> String:
  wk.param.go(String.split(q, '&'), k)


def wk.solve.req(s: Socket, +jobs: Chan(Req), +q: String) -> IO(Unit):
  wk.solve.got(s, jobs, wk.param(q, "v"), C.cube.read(wk.param(q, "m")))

def wk.route.go(health: Bool, solve: Bool, s: Socket, +jobs: Chan(Req), +path: String) -> IO(Unit):
  match health solve:
    case True{} _:
      wk.text(s, "200 OK", "ok\n")
    case False{} True{}:
      wk.solve.req(s, jobs, String.drop(path, 7n))
    case False{} False{}:
      wk.text(s, "404 Not Found", "not found\n")

def wk.target(req: String) -> String:
  +line = Maybe.default(&2, String, List.get(&2, String, String.split(req, '\n'), 0n), "")
  Maybe.default(&2, String, List.get(&2, String, String.split(line, ' '), 1n), "/")

def wk.req(rd: Socket & Poll<&1, &1, Result<&1, &1, U32 & String, Maybe<&1, String>>, Unit>, +jobs: Chan(Req)) -> IO(Unit):
  (s, p) = rd
  match p:
    case Ready{Done{Some{req}}}:
      +path = wk.target(req)
      wk.route.go(String.eq(path, "/health"), String.starts_with(path, "/solve?"), s, jobs, path)
    case _:
      Socket.close(s)

def wk.handle(s: Socket, +jobs: Chan(Req)) -> IO(Unit):
  do IO<Unit>:
    rd : Socket & Poll<&1, &1, Result<&1, &1, U32 & String, Maybe<&1, String>>, Unit> <- TCP.try_recv(s, 16384, 5000)
    wk.req(rd, jobs)

def wk.conn(m: Listener & Result<&1, &1, U32 & String, Socket>, +jobs: Chan(Req)) -> IO(Listener):
  (l, res) = m
  match res:
    case Done{s}:
      do IO<Listener>:
        IO.spawn(Unit, wk.handle(s, jobs))
        return l
    case Fail{e}:
      IO.pure(Listener, l)

@unsafe
def wk.serve(l: Listener, +jobs: Chan(Req)) -> IO(Unit):
  do IO<Unit>:
    m : Listener & Result<&1, &1, U32 & String, Socket> <- TCP.accept(l)
    l2 : Listener <- wk.conn(m, jobs)
    wk.serve(l2, jobs)

type Args is Data:
  Args{+port: String, +tables: String}

def wk.args(xs: List<String>) -> Args:
  match xs:
    case Con{a, Con{b, Con{c, t}}}:
      Args{b, c}
    case _:
      Args{"8095", "tables.bin"}

@unsafe
def wk.main(a: Args, +t0: Nat) -> IO(Unit):
  match a:
    case Args{+port, +tables}:
      do IO<Unit>:
        IO.print("reading the tables")
        t : Array<U32> <- F.fs.load(tables)
        +t1 : Nat <- IO.now()
        +jobs : Chan(Req) <- Chan.new(Req, 64)
        l : Listener <- IO.try(Listener, TCP.listen("127.0.0.1", Maybe.default(&2, U32, U32.read(port), 8095)))
        IO.print("tables read in " ++ Nat.show(Nat.sub(t1, t0)) ++ " ms: solving on http://127.0.0.1:" ++ port)
        IO.spawn(Unit, wk.serve(l, jobs))
        s : Array<U32> & List<&2, Req> <- wk.both(t, Nil{})
        wk.loop(1000000000n, None{}, s, jobs)

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    +t0 : Nat <- IO.now()
    wk.main(wk.args(args), t0)
