import Base
import ./Cube.bend as C
import ./Search.bend as S
import ./Solve.bend as V
import ./Opt.bend as O
import ./Fast.bend as F
import ./TwoPhase.bend as P
import ./Sym.bend as Y

# The solver, as a process of its own (the page's server, Server.bend, sends
# it the cubes, and kills it if it ever holds one past the hard limit):
#
#   cube-solver <port> <tables>
#
# reads the tables (Build.bend's file, about 40 s), makes two-phase's
# (TwoPhase.bend, about 2 s), then answers on 127.0.0.1:<port> (not before:
# so a server asks a standby meanwhile):
#   GET /health              "ok", from the computation that takes
#                            connections, so only if the event loop turns
#   GET /solve?v=V&m=3.10.17 a shortest solution of the cube the moves make,
#                            for visitor V (any name, or none)
#
# One computation solves, one cube at a time. First a short way, at once:
# two-phase's answer, or the scramble undone if that is shorter. Then the
# shortest, on every core (Fast.bend's search, a chunk of prefixes a step, a
# 3 ms sleep between steps so the rest runs), its bounds kept below the
# short way's length: once they all have no solution, the short way is a
# shortest one. Between steps it takes the cubes that came in: the same
# cube again from the same visitor joins the search under way (its time
# limit counts from the first ask); another cube of theirs cancels it; past
# wk.cap() waiting, a cube is turned away. A search stops wk.limit() ms
# after its cube was first asked for. Every asker hears within wk.wait() ms:
# the answer, or how far the search got ("working", every wk.every() ms, with
# the short way), or that the cube waits behind others ("queued"); the page
# then asks again. Answers are kept a while, so asking again for a cube just
# answered gets the same answer at once.
#
# The answer: a shortest solution, four lines: its moves, the nodes searched,
# the milliseconds since the cube was first asked for, and "ok" when the
# scramble then the solution leaves the cube solved (checked here by
# Cube.bend; the page checks it again). A short way not proven shortest
# (wk.rough): "short" (the time ran out) or "working", the nodes, the
# milliseconds, "ok" (checked), the bound being searched (every shorter one
# was searched in full, so the shortest has at least that many moves), the
# moves, the time limit. Else a word (wk.word): "busy", "cancelled",
# "queued", "none" (cannot happen), then the nodes, the milliseconds, "ok",
# the bound.
#
# Every def is prefixed `wk.`.

def wk.limit() -> Nat:
  120000n

# how long an asker waits for a word from the solver: then "queued" (its
# cube waits behind others'), and the page asks again; under Safari's 60 s
# and Cloudflare's 100 s
def wk.wait() -> U32:
  20000

# how often the askers of the cube being solved hear how far it got
def wk.every() -> Nat:
  15000n

def wk.cap() -> U32:
  6

# answers kept, so a cube asked again after its answer gets it at once
def wk.keep() -> Nat:
  32n

# A request: who, which cube (its moves' wire form), the moves, where the
# answer goes, when that cube was first asked for
type Req is Data:
  Req{+vis: String, +key: String, +ms: List<&2, U32>, +reply: Chan(String), +at: Nat}

# An answer kept: whose, which cube, what
type Kept is Data:
  Kept{+vis: String, +key: String, +body: String}

# The solve under way: whose, which cube, its moves, who waits for it (their
# replies), when they last heard, the shortest way known (two-phase's, or
# the moves undone) and its length (the bounds searched stay below it), and
# when the cube was first asked for (its time limit counts from there)
type Job is Data:
  Job{+vis: String, +key: String, +ms: List<&2, U32>, +askers: List<&2, Chan(String)>, +said: Nat,
      +short: List<&2, U32>, +cap: U32, +t0: Nat}

# what a step found: carry on, stop (time, or every shorter bound searched),
# or cancel (the visitor asked for another cube)
type WPh is Data:
  WGo{}
  WLate{}
  WOver{}
  WCancel{}

type WS is Data:
  WS{+ph: WPh, +news: List<&2, Req>, +job: Job}

# a solve's end: what the search found, how it ended, the requests that came
# meanwhile, the job
type Fin is Data:
  Fin{+ans: V.Ans, +how: WPh, +news: List<&2, Req>, +job: Job}

def wk.same(+a: String, +b: String) -> Bool:
  Bool.and(Bool.not(String.is_empty(a)), String.eq(a, b))

def wk.len(q: List<&2, Req>) -> U32:
  match q:
    case Nil{}:
      0
    case Con{r, t}:
      U32.add(wk.len(t), 1)

def wk.mlen(xs: List<&2, U32>) -> U32:
  match xs:
    case Nil{}:
      0
    case Con{x, t}:
      U32.add(wk.mlen(t), 1)

# Answers
# -------

# a word for an answer without moves, then the nodes, the milliseconds, "ok",
# and the bound being searched (every shorter one was searched in full: the
# shortest solution has at least that many moves)
def wk.word(+w: String, +k: U32, +dt: Nat, +b: U32) -> String:
  w ++ "\n" ++ U32.show(k) ++ "\n" ++ Nat.show(dt) ++ "\nok\n" ++ U32.show(b) ++ "\n"

def wk.checks(+ms: List<&2, U32>, +sol: List<&2, U32>) -> String:
  Bool.pick(String, C.cube.is_solved(C.cube.apply(sol, C.cube.apply(ms, C.cube.solved()))), "ok", "WRONG")

# a shortest solution: its moves, the nodes, the milliseconds, "ok" if it
# solves the cube
def wk.best(+ms: List<&2, U32>, +sol: List<&2, U32>, +k: U32, +dt: Nat) -> String:
  C.cube.nums(sol) ++ "\n" ++ U32.show(k) ++ "\n" ++ Nat.show(dt) ++ "\n" ++ wk.checks(ms, sol) ++ "\n"

# a solution not known to be the shortest ("short" when the time ran out,
# "working" while the search goes on): the word, the nodes, the
# milliseconds since the cube was first asked for, "ok" if it solves the
# cube, the bound being searched, the moves, and the time limit
def wk.rough(+w: String, +ms: List<&2, U32>, +sol: List<&2, U32>, +k: U32, +dt: Nat, +b: U32) -> String:
  w ++ "\n" ++ U32.show(k) ++ "\n" ++ Nat.show(dt) ++ "\n" ++ wk.checks(ms, sol) ++ "\n" ++ U32.show(b) ++ "\n"
    ++ C.cube.nums(sol) ++ "\n" ++ Nat.show(wk.limit()) ++ "\n"

def wk.body(d: Fin, +dt: Nat) -> String:
  match d:
    case Fin{V.Ans{Some{+sol}, k, b}, how, news, Job{vis, key, +ms, askers, said, short, cap, t0}}:
      wk.best(ms, sol, k, dt)
    case Fin{V.Ans{None{}, k, b}, WOver{}, news, Job{vis, key, +ms, askers, said, +short, cap, t0}}:
      # every bound below the short way's length had no solution: it is a
      # shortest one
      wk.best(ms, short, k, dt)
    case Fin{V.Ans{None{}, k, b}, WLate{}, news, Job{vis, key, +ms, askers, said, +short, cap, t0}}:
      wk.rough("short", ms, short, k, dt, b)
    case Fin{V.Ans{None{}, k, b}, WCancel{}, news, job}:
      wk.word("cancelled", k, dt, b)
    case Fin{V.Ans{None{}, k, b}, WGo{}, news, job}:
      wk.word("none", k, dt, b)

def wk.sent(r: Result<&1, &1, String, Unit>) -> IO(Unit):
  IO.pure(Unit, Unit{})

def wk.say(+reply: Chan(String), +body: String) -> IO(Unit):
  do IO<Unit>:
    r : Result<&1, &1, String, Unit> <- Chan.send(String, reply, body)
    wk.sent(r)

# the same body to each of the replies
@unsafe
def wk.say.all(rs: List<&2, Chan(String)>, +body: String) -> IO(Unit):
  match rs:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case Con{+r, rest}:
      do IO<Unit>:
        wk.say(r, body)
        wk.say.all(rest, body)

# tell each of rs the word w
@unsafe
def wk.tell(rs: List<&2, Req>, +w: String) -> IO(Unit):
  match rs:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case Con{+r, rest}:
      match r:
        case Req{v, k, ms, +reply, at}:
          do IO<Unit>:
            wk.say(reply, wk.word(w, 0, 0n, 0))
            wk.tell(rest, w)

# Answers kept
# ------------

# the answer kept for (vis, key), if any
def wk.find(ks: List<&2, Kept>, +vis: String, +key: String) -> Maybe<&2, String>:
  match ks:
    case Nil{}:
      None{}
    case Con{+k, rest}:
      match k:
        case Kept{+v, +y, +body}:
          Bool.pick(Maybe<&2, String>, Bool.and(wk.same(v, vis), String.eq(y, key)), Some{body}, wk.find(rest, vis, key))

# one more kept, the oldest forgotten past wk.keep()
def wk.kept(+k: Kept, +ks: List<&2, Kept>) -> List<&2, Kept>:
  List.take(&2, Kept, k <> ks, wk.keep())

# The queue
# ---------

# the queue without the visitor's requests (vis: none, keeps all), and those
def wk.drop(q: List<&2, Req>, +vis: String, +keep: List<&2, Req>, +out: List<&2, Req>) -> List<&2, Req> & List<&2, Req>:
  match q:
    case Nil{}:
      (List.reverse(&2, Req, keep), out)
    case Con{+r, rest}:
      match r:
        case Req{+v, +k, +ms, +reply, +at}:
          +gone = wk.same(v, vis)
          wk.drop(rest, vis, Bool.pick(List<&2, Req>, gone, keep, r <> keep), Bool.pick(List<&2, Req>, gone, r <> out, out))

# the first time cube key was asked for among rs (else at)
def wk.first(rs: List<&2, Req>, +key: String, +at: Nat) -> Nat:
  match rs:
    case Nil{}:
      at
    case Con{+r, rest}:
      match r:
        case Req{v, +k, ms, reply, +a}:
          wk.first(rest, key, Bool.pick(Nat, Bool.and(String.eq(k, key), Nat.is_lt(a, at)), a, at))

# the requests of rs for other cubes than key
def wk.others(rs: List<&2, Req>, +key: String) -> List<&2, Req>:
  match rs:
    case Nil{}:
      Nil{}
    case Con{+r, +rest}:
      match r:
        case Req{v, +k, ms, reply, at}:
          Bool.pick(List<&2, Req>, String.eq(k, key), wk.others(rest, key), r <> wk.others(rest, key))

def wk.vis(+r: Req) -> String:
  match r:
    case Req{+v, k, ms, reply, at}:
      v

def wk.key(+r: Req) -> String:
  match r:
    case Req{v, +k, ms, reply, at}:
      k

def wk.at(+r: Req) -> Nat:
  match r:
    case Req{v, k, ms, reply, +at}:
      at

# r, its cube first asked for when the visitor's earlier asks for it were
def wk.since(+r: Req, +gone: List<&2, Req>) -> Req:
  match r:
    case Req{+v, +k, +ms, +reply, +at}:
      Req{v, k, ms, reply, wk.first(gone, k, at)}

@unsafe
def wk.add.go(full: Bool, s: List<&2, Req> & List<&2, Req>, +r: Req) -> IO(List<&2, Req>):
  match full:
    case True{}:
      (q, gone) = s
      do IO<List<&2, Req>>:
        wk.tell(wk.others(gone, wk.key(r)), "cancelled")
        wk.tell([r], "busy")
        return q
    case False{}:
      (+q, +gone) = s
      do IO<List<&2, Req>>:
        wk.tell(wk.others(gone, wk.key(r)), "cancelled")
        return List.append(&2, Req, q, [wk.since(r, gone)])

# r into the queue q: the visitor's earlier asks for other cubes cancelled,
# for the same cube merged into r (its first ask's time kept); turned away
# if the queue is full
@unsafe
def wk.add(q: List<&2, Req>, +r: Req) -> IO(List<&2, Req>):
  +s = wk.drop(q, wk.vis(r), Nil{}, Nil{})
  wk.add.go(U32.is_ge(wk.len(Pair.fst(List<&2, Req>, List<&2, Req>, s)), wk.cap()), s, r)

# r answered at once if its answer is kept, else queued
@unsafe
def wk.take(m: Maybe<&2, String>, q: List<&2, Req>, +r: Req) -> IO(List<&2, Req>):
  match m:
    case Some{+body}:
      match r:
        case Req{v, k, ms, +reply, at}:
          do IO<List<&2, Req>>:
            wk.say(reply, body)
            return q
    case None{}:
      wk.add(q, r)

@unsafe
def wk.adds(rs: List<&2, Req>, q: List<&2, Req>, +ks: List<&2, Kept>) -> IO(List<&2, Req>):
  match rs:
    case Nil{}:
      IO.pure(List<&2, Req>, q)
    case Con{+r, rest}:
      do IO<List<&2, Req>>:
        q2 : List<&2, Req> <- wk.take(wk.find(ks, wk.vis(r), wk.key(r)), q, r)
        wk.adds(rest, q2, ks)

# Between steps
# -------------

def wk.base(+now: Nat, +job: Job, +limit: Nat, +b: U32) -> WPh:
  match job:
    case Job{vis, key, ms, askers, said, short, +cap, +t0}:
      Bool.pick(WPh, U32.is_ge(b, cap), WOver{}, Bool.pick(WPh, Nat.is_gt(Nat.sub(now, t0), limit), WLate{}, WGo{}))

# the job with one more asker
def wk.join(+job: Job, +reply: Chan(String)) -> Job:
  match job:
    case Job{+vis, +key, +ms, +askers, +said, +short, +cap, +t0}:
      Job{vis, key, ms, reply <> askers, said, short, cap, t0}

# what came in (r) while the job runs: kept answer at once; its cube again
# (the same visitor): one more asker, the search goes on; another cube of
# the visitor's: cancel; else, to the queue after
@unsafe
def wk.came(m: Maybe<&2, String>, +r: Req, +job: Job, +news: List<&2, Req>, +ph: WPh) -> IO(WS):
  match m r job:
    case Some{+body} Req{v, k, ms, +reply, at} _:
      do IO<WS>:
        wk.say(reply, body)
        return WS{ph, news, job}
    case None{} Req{+v, +k, ms, +reply, at} Job{+vis, +key, jms, ja, js, jsh, jc, jt}:
      +mine = wk.same(v, vis)
      +again = Bool.and(mine, String.eq(k, key))
      IO.pure(WS, WS{Bool.pick(WPh, Bool.and(mine, Bool.not(again)), WCancel{}, ph),
        Bool.pick(List<&2, Req>, again, news, List.append(&2, Req, news, [r])),
        Bool.pick(Job, again, wk.join(job, reply), job)})

@unsafe
def wk.poll(p: Poll<&1, &1, Maybe<&1, Req>, Unit>, +job: Job, +news: List<&2, Req>, +ks: List<&2, Kept>, +ph: WPh) -> IO(WS):
  match p:
    case Ready{Some{+r}}:
      wk.came(wk.find(ks, wk.vis(r), wk.key(r)), r, job, news, ph)
    case _:
      IO.pure(WS, WS{ph, news, job})

# every wk.every() ms, the askers hear how far the search got, and the short
# way known; then they ask again (and join it)
@unsafe
def wk.tell.go(due: Bool, +ws: WS, +now: Nat, +b: U32, +k: U32) -> IO(WS):
  match due ws:
    case False{} _:
      IO.pure(WS, ws)
    case True{} WS{+ph, +news, Job{+vis, +key, +ms, +askers, said, +short, +cap, +t0}}:
      do IO<WS>:
        wk.say.all(askers, wk.rough("working", ms, short, k, Nat.sub(now, t0), b))
        return WS{ph, news, Job{vis, key, ms, Nil{}, now, short, cap, t0}}

def wk.due(+ws: WS, +now: Nat) -> Bool:
  match ws:
    case WS{ph, news, Job{vis, key, ms, +askers, +said, short, cap, t0}}:
      Bool.and(Bool.not(List.is_empty(&2, Chan(String), askers)), Nat.is_ge(Nat.sub(now, said), wk.every()))

@unsafe
def wk.tell.if(+ws: WS, +now: Nat, +b: U32, +k: U32) -> IO(WS):
  wk.tell.go(wk.due(ws, now), ws, now, b, k)

# The search
# ----------

# the prefixes, made the first time a bound needs them (from F.fs.par() on):
# a cube solved in fewer moves never pays for them
def wk.pre(need: Bool, +ps: List<&2, O.Pre>, +v: O.View) -> List<&2, O.Pre>:
  match need:
    case True{}:
      O.op.prefixes(3n, v)
    case False{}:
      ps

def wk.ws.job(+ws: WS) -> Job:
  match ws:
    case WS{ph, news, +job}:
      job

def wk.job.cap(+job: Job) -> U32:
  match job:
    case Job{vis, key, ms, askers, said, short, +cap, t0}:
      cap

# Fast.bend's fs.io.go, taking in requests between steps, and telling the
# askers how it goes
@unsafe
def wk.run(k: Nat, ws: WS, st: F.Step, +b: U32, +tot: U32, +n: O.Node, +v: O.View, +ps: List<&2, O.Pre>, +limit: Nat, +jobs: Chan(Req), +ks: List<&2, Kept>) -> IO(Array<U32> & Fin):
  match k ws:
    case 0n WS{ph, +news, +job}:
      match st:
        case F.Step{r, rest}:
          (t, res) = r
          IO.pure(Array<U32> & Fin, (t, Fin{V.Ans{None{}, tot, b}, WLate{}, news, job}))
    case 1n+q WS{WLate{}, +news, +job}:
      match st:
        case F.Step{r, rest}:
          (t, res) = r
          IO.pure(Array<U32> & Fin, (t, Fin{V.Ans{None{}, tot, b}, WLate{}, news, job}))
    case 1n+q WS{WOver{}, +news, +job}:
      match st:
        case F.Step{r, rest}:
          (t, res) = r
          IO.pure(Array<U32> & Fin, (t, Fin{V.Ans{None{}, tot, b}, WOver{}, news, job}))
    case 1n+q WS{WCancel{}, +news, +job}:
      match st:
        case F.Step{r, rest}:
          (t, res) = r
          IO.pure(Array<U32> & Fin, (t, Fin{V.Ans{None{}, tot, b}, WCancel{}, news, job}))
    case 1n+q WS{WGo{}, +news, +job}:
      match st:
        case F.Step{r, +rest}:
          (t, res) = r
          match res:
            case S.Res{f, +c}:
              match f:
                case Some{+xs}:
                  IO.pure(Array<U32> & Fin, (t, Fin{V.Ans{Some{xs}, U32.add(tot, c), b}, WGo{}, news, job}))
                case None{}:
                  +done = F.fs.empty(rest)
                  +nb = Bool.pick(U32, done, U32.add(b, 1), b)
                  +cap = wk.job.cap(job)
                  +ps2 = wk.pre(Bool.and(Bool.and(U32.is_ge(nb, F.fs.par()), U32.is_lt(nb, cap)), F.fs.empty(ps)), ps, v)
                  st2 = F.fs.work(t, nb, Bool.pick(List<&2, O.Pre>, done, ps2, rest), n, cap)
                  +tot2 = U32.add(tot, c)
                  do IO<Array<U32> & Fin>:
                    IO.sleep(3)
                    +now : Nat <- IO.now()
                    p : Poll<&1, &1, Maybe<&1, Req>, Unit> <- Chan.try_recv(Req, jobs, 0)
                    ws2 : WS <- wk.poll(p, job, news, ks, wk.base(now, job, limit, nb))
                    ws3 : WS <- wk.tell.if(ws2, now, nb, tot2)
                    wk.run(q, ws3, st2, nb, tot2, n, v, ps2, limit, jobs, ks)

@unsafe
def wk.start.go(zero: Bool, t: Array<U32>, +h: U32, +n: O.Node, +v: O.View, +job: Job, +jobs: Chan(Req), +ks: List<&2, Kept>) -> IO(Array<U32> & Fin):
  match zero:
    case True{}:
      IO.pure(Array<U32> & Fin, (t, Fin{V.Ans{Some{Nil{}}, 0, 0}, WGo{}, Nil{}, job}))
    case False{}:
      wk.run(100000n, WS{WGo{}, Nil{}, job}, F.Step{(t, S.Res{None{}, 0}), Nil{}}, U32.sub(h, 1), 0, n, v, Nil{}, wk.limit(), jobs, ks)

@unsafe
def wk.start(r: Array<U32> & U32, +n: O.Node, +v: O.View, +job: Job, +jobs: Chan(Req), +ks: List<&2, Kept>) -> IO(Array<U32> & Fin):
  (t, +h) = r
  wk.start.go(U32.is_zero(h), t, h, n, v, job, jobs, ks)

# the job of a request, once two-phase (TwoPhase.bend) has a short way: the
# shorter of its answer and the scramble undone (so never longer than the
# scramble); its length caps the bounds searched
def wk.job.go(+r: Req, +b: P.Best, +now: Nat) -> Job:
  match r b:
    case Req{+vis, +key, +ms, +reply, +at} P.Best{Some{+sol}, +len, tries, nodes}:
      +inv = C.cube.inv(ms)
      +ok = Bool.and(U32.is_lt(len, wk.mlen(inv)), C.cube.is_solved(C.cube.apply(sol, C.cube.apply(ms, C.cube.solved()))))
      Job{vis, key, ms, [reply], Nat.sub(now, 13000n), Bool.pick(List<&2, U32>, ok, sol, inv), Bool.pick(U32, ok, len, wk.mlen(inv)), at}
    case Req{+vis, +key, +ms, +reply, +at} P.Best{None{}, len, tries, nodes}:
      +inv = C.cube.inv(ms)
      Job{vis, key, ms, [reply], Nat.sub(now, 13000n), inv, wk.mlen(inv), at}

# Two-phase on each of the cube's three axes (the cube as it is, and turned
# by URF3 once and twice, Sym.bend), the shortest answer kept: a solution of
# the cube turned k times, its moves turned back, solves the cube
def wk.tp.len(+b: P.Best) -> U32:
  match b:
    case P.Best{s, +len, tries, nodes}:
      len

# the better of a (the cube's own) and b (the turned cube's), b's moves
# turned back by back
def wk.tp.pick(+a: P.Best, +b: P.Best, +back: Bool) -> P.Best:
  match a b:
    case _ P.Best{Some{+xs}, +len, +tries, +nodes}:
      Bool.pick(P.Best, U32.is_lt(len, wk.tp.len(a)),
        P.Best{Some{Bool.pick(List<&2, U32>, back, Y.sy.urf.ms(Y.sy.urf.ms(xs)), Y.sy.urf.ms(xs))}, len, tries, nodes}, a)
    case _ P.Best{None{}, len, tries, nodes}:
      a

def wk.tp.third(r: Array<U32> & P.Best, +a: P.Best) -> Array<U32> & P.Best:
  (t, +b) = r
  (t, wk.tp.pick(a, b, False{}))

def wk.tp.second(r: Array<U32> & P.Best, +a: P.Best, +t2: U32, +r2: U32, +ms: List<&2, U32>) -> Array<U32> & P.Best:
  (t, +b) = r
  wk.tp.third(P.tp.solve(t, t2, r2, C.cube.apply(Y.sy.urf.ms(Y.sy.urf.ms(ms)), C.cube.solved())), wk.tp.pick(a, b, True{}))

def wk.tp.first(r: Array<U32> & P.Best, +t1: U32, +r1: U32, +t2: U32, +r2: U32, +ms: List<&2, U32>) -> Array<U32> & P.Best:
  (t, +a) = r
  wk.tp.second(P.tp.solve(t, t1, r1, C.cube.apply(Y.sy.urf.ms(ms), C.cube.solved())), a, t2, r2, ms)

def wk.tp.node(t: Array<U32>, +n: O.Node, +ms: List<&2, U32>) -> Array<U32> & P.Best:
  match n:
    case O.Node{cp, t0, r0, t1, r1, t2, r2}:
      wk.tp.first(P.tp.solve(t, t0, r0, C.cube.apply(ms, C.cube.solved())), t1, r1, t2, r2, ms)

@unsafe
def wk.solve.tp(r: Array<U32> & P.Best, +req: Req, +n: O.Node, +v: O.View, +jobs: Chan(Req), +ks: List<&2, Kept>) -> IO(Array<U32> & Fin):
  (t, +b) = r
  do IO<Array<U32> & Fin>:
    +now : Nat <- IO.now()
    wk.start(O.op.bound(t, n), n, v, wk.job.go(req, b, now), jobs, ks)

@unsafe
def wk.solve(t: Array<U32>, +req: Req, +jobs: Chan(Req), +ks: List<&2, Kept>) -> IO(Array<U32> & Fin):
  match req:
    case Req{vis, key, +ms, reply, at}:
      +v = O.op.view(ms)
      +n = O.op.view.node(v)
      wk.solve.tp(wk.tp.node(t, n, ms), req, n, v, jobs, ks)

# The solver's state between cubes: the tables, the queue, the answers kept
type St is Type:
  St{t: Array<U32>, +q: List<&2, Req>, +ks: List<&2, Kept>}

def wk.st(t: Array<U32>, +q: List<&2, Req>, +ks: List<&2, Kept>) -> IO(St):
  IO.pure(St, St{t, q, ks})

def wk.fin.news(+d: Fin) -> List<&2, Req>:
  match d:
    case Fin{a, h, +news, j}:
      news

def wk.fin.job(+d: Fin) -> Job:
  match d:
    case Fin{a, h, n, +job}:
      job

def wk.fin.cancelled(+d: Fin) -> Bool:
  match d:
    case Fin{a, WCancel{}, n, j}:
      True{}
    case Fin{a, h, n, j}:
      False{}

# a solve done: the answer to its askers (and kept, unless cancelled), the
# cubes that came meanwhile queued (or answered from what is kept)
@unsafe
def wk.after.say(t: Array<U32>, +d: Fin, +rest: List<&2, Req>, +ks: List<&2, Kept>, +vis: String, +key: String, +askers: List<&2, Chan(String)>, +body: String) -> IO(St):
  +ks2 = Bool.pick(List<&2, Kept>, wk.fin.cancelled(d), ks, wk.kept(Kept{vis, key, body}, ks))
  do IO<St>:
    IO.print("solve " ++ vis ++ " " ++ key ++ " -> " ++ String.join(String.split(body, '\n'), " "))
    wk.say.all(askers, body)
    q : List<&2, Req> <- wk.adds(wk.fin.news(d), rest, ks2)
    wk.st(t, q, ks2)

@unsafe
def wk.after.job(+job: Job, t: Array<U32>, +d: Fin, +rest: List<&2, Req>, +ks: List<&2, Kept>) -> IO(St):
  match job:
    case Job{+vis, +key, ms, +askers, said, short, cap, +t0}:
      do IO<St>:
        +t1 : Nat <- IO.now()
        wk.after.say(t, d, rest, ks, vis, key, askers, wk.body(d, Nat.sub(t1, t0)))

@unsafe
def wk.after(r: Array<U32> & Fin, +rest: List<&2, Req>, +ks: List<&2, Kept>) -> IO(St):
  (t, +d) = r
  wk.after.job(wk.fin.job(d), t, d, rest, ks)

@unsafe
def wk.one(t: Array<U32>, +job: Req, +rest: List<&2, Req>, +jobs: Chan(Req), +ks: List<&2, Kept>) -> IO(St):
  do IO<St>:
    r : Array<U32> & Fin <- wk.solve(t, job, jobs, ks)
    wk.after(r, rest, ks)

# the solver: the queue's first solved, then the next; with none, wait for one
@unsafe
def wk.loop(k: Nat, m: Maybe<&1, Req>, s: St, +jobs: Chan(Req)) -> IO(Unit):
  match k m s:
    case 0n _ St{t, q, ks}:
      IO.pure(Unit, Unit{})
    case 1n+p Some{+r} St{t, +q, +ks}:
      do IO<Unit>:
        q2 : List<&2, Req> <- wk.take(wk.find(ks, wk.vis(r), wk.key(r)), q, r)
        s2 : St <- wk.st(t, q2, ks)
        wk.loop(p, None{}, s2, jobs)
    case 1n+p None{} St{t, +q, +ks}:
      match q:
        case Nil{}:
          do IO<Unit>:
            m2 : Maybe<&1, Req> <- Chan.recv(Req, jobs)
            s2 : St <- wk.st(t, Nil{}, ks)
            wk.loop(p, m2, s2, jobs)
        case Con{+job, +rest}:
          do IO<Unit>:
            s2 : St <- wk.one(t, job, rest, jobs, ks)
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

# the answer, or after wk.wait() ms "queued" (the page asks again)
def wk.answer(s: Socket, m: Maybe<&1, Maybe<&1, String>>) -> IO(Unit):
  match m:
    case Some{Some{+body}}:
      wk.text(s, "200 OK", body)
    case _:
      wk.text(s, "200 OK", wk.word("queued", 0, 0n, 0))

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
    +at : Nat <- IO.now()
    r : Result<&1, &1, Req, Unit> <- Chan.send(Req, jobs, Req{vis, C.cube.nums(ms), ms, reply, at})
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
        t0r : Array<U32> <- F.fs.load(tables)
        t : Array<U32> <- IO.pure(Array<U32>, P.tp.tables(t0r))
        +t1 : Nat <- IO.now()
        +jobs : Chan(Req) <- Chan.new(Req, 64)
        l : Listener <- IO.try(Listener, TCP.listen("127.0.0.1", Maybe.default(&2, U32, U32.read(port), 8095)))
        IO.print("tables read and two-phase's made in " ++ Nat.show(Nat.sub(t1, t0)) ++ " ms: solving on http://127.0.0.1:" ++ port)
        IO.spawn(Unit, wk.serve(l, jobs))
        s : St <- wk.st(t, Nil{}, Nil{})
        wk.loop(1000000000n, None{}, s, jobs)

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    +t0 : Nat <- IO.now()
    wk.main(wk.args(args), t0)
