import Base
import ../bend-frp/Frp.bend as F
import ../bend-frp/Web.bend as W
import ../Cube.bend as C

# El cubo de Edgar: the page. A bend-frp app (Web.bend): every state is a
# fold of the page's inputs, and the view a function of the state.
#
# The cube itself lives here, as Cube.bend's group element: a turn is shown by
# handing the 3D view (cube3d.js, the host's "turn") the move to animate and
# the 54 stickers the cube has after it; the view draws nothing of its own.
#
#   Scramble    a random scramble from solved, animated; at once this
#               device (web/solver.js) is asked for a shortest solution
#   U .. B'     a turn of a face by hand: the cube keeps the position
#   Solve       a shortest solution of the position the cube is in
#   Next step   the solution's next move, animated
#   Play        every move left, one after the other
#   Reset       the solved cube
#
# The position is kept as moves from solved (pos), each run of turns of one
# face merged into one (LAWS.bend: same_face_merge), so it is the cube the
# solver is asked about. A solve's answer is checked here too, by Cube.bend,
# before it is shown. An answer that comes after the position changed is
# dropped: each request is numbered (gen), and only the last one's counts.

type S is Data:
  S{+cube: C.Cube, +queue: List<&2, U32>, +busy: Bool, +auto: Bool, +pos: List<&2, U32>,
    +sol: Maybe<&2, List<&2, U32>>, +step: U32, +asked: Bool, +info: String, +bad: Bool,
    +opt: Bool, +gen: U32, +wait: U32, +who: String}

def init() -> S:
  S{C.cube.solved(), [], False{}, False{}, [], None{}, 0, False{}, "", False{}, True{}, 0, 0, ""}

# a fresh page, known to the solver as who
def init.as(+who: String) -> S:
  S{C.cube.solved(), [], False{}, False{}, [], None{}, 0, False{}, "", False{}, True{}, 0, 0, who}

# What an input means
type Msg is Data:
  MStart{+seed: U32}
  MHow{}
  MOwn{}
  MCol{}
  MRoute{+v: String}
  MCopy{}
  MScramble{+seed: U32}
  MTurn{+m: U32}
  MSolve{}
  MNext{}
  MPlay{}
  MReset{}
  MTurned{}
  MSolved{+gen: U32, +body: String}
  MFailed{+gen: U32}
  MTick{+gen: U32}
  MAgain{+gen: U32}
  MOther{}

def line(+ls: List<&2, String>, +i: Nat) -> String:
  Maybe.default(&2, String, List.get(&2, String, ls, i), "")

def num(+s: String) -> U32:
  Maybe.default(&2, U32, U32.read(s), 0)

# The input's time, as a seed: inputs never share a time (bend-frp's
# time_after), so two scrambles never share one
def seed.of(+t: F.Time) -> U32:
  match t:
    case F.Time{sec, frac}:
      U32.or(U32.xor(U32.mul(sec, 2654435761), frac), 1)

# "sol7" is request 7's answer; "sol7:failed", that it did not come
def msg.sol(+tag: String, +v: String) -> Msg:
  +g = num(line(String.split(String.drop(tag, 3n), ':'), 0n))
  Bool.pick(Msg, String.ends_with(tag, ":failed"), MFailed{g}, MSolved{g, v})

# whether s is a move's number, 0..17
def msg.move.go(m: Maybe<&2, U32>) -> Bool:
  match m:
    case Some{+x}:
      U32.is_lt(x, 18)
    case None{}:
      False{}

def msg.move(+s: String) -> Bool:
  msg.move.go(U32.read(s))

# "t12" is a hand's turn, move 12
def msg.of(+t: F.Time, +tag: String, +v: String) -> Msg:
  Bool.pick(Msg, String.eq(tag, "start"), MStart{seed.of(t)},
  Bool.pick(Msg, String.eq(tag, "howto"), MHow{},
  Bool.pick(Msg, String.eq(tag, "own"), MOwn{},
  Bool.pick(Msg, String.eq(tag, "colors"), MCol{},
  Bool.pick(Msg, String.eq(tag, "route"), MRoute{v},
  Bool.pick(Msg, String.eq(tag, "copy"), MCopy{},
  Bool.pick(Msg, String.eq(tag, "scramble"), MScramble{seed.of(t)},
  Bool.pick(Msg, String.eq(tag, "solve"), MSolve{},
  Bool.pick(Msg, String.eq(tag, "next"), MNext{},
  Bool.pick(Msg, String.eq(tag, "play"), MPlay{},
  Bool.pick(Msg, String.eq(tag, "reset"), MReset{},
  Bool.pick(Msg, String.eq(tag, "turned"), MTurned{},
  Bool.pick(Msg, String.starts_with(tag, "sol"), msg.sol(tag, v),
  Bool.pick(Msg, String.starts_with(tag, "tick"), MTick{num(String.drop(tag, 4n))},
  Bool.pick(Msg, String.starts_with(tag, "again"), MAgain{num(String.drop(tag, 5n))},
  Bool.pick(Msg, Bool.and(String.starts_with(tag, "t"), msg.move(String.drop(tag, 1n))), MTurn{num(String.drop(tag, 1n))},
    MOther{}))))))))))))))))

# Positions
# ---------

# a turn pushed on a stack of turns (last first): merged with the one before
# if both turn the same face, their quarter turns added mod 4, and gone if
# that is none (LAWS.bend: same_face_merge, quarter_turn_order)
def pos.merge(same: Bool, +m: U32, +top: U32, +rest: List<&2, U32>) -> List<&2, U32>:
  match same:
    case False{}:
      m <> (top <> rest)
    case True{}:
      +q = U32.mod(U32.add(U32.add(U32.mod(top, 3), U32.mod(m, 3)), 2), 4)
      Bool.pick(List<&2, U32>, U32.is_zero(q), rest, U32.add(U32.sub(top, U32.mod(top, 3)), U32.sub(q, 1)) <> rest)

def pos.push(+m: U32, st: List<&2, U32>) -> List<&2, U32>:
  match st:
    case Nil{}:
      [m]
    case Con{+top, +rest}:
      pos.merge(U32.is_eq(U32.div(top, 3), U32.div(m, 3)), m, top, rest)

def pos.go(ms: List<&2, U32>, st: List<&2, U32>) -> List<&2, U32>:
  match ms:
    case Nil{}:
      List.reverse(&2, U32, st)
    case Con{+m, t}:
      pos.go(t, pos.push(m, st))

# moves with each run of one face's turns merged: the same cube
def pos.simp(ms: List<&2, U32>) -> List<&2, U32>:
  pos.go(ms, Nil{})

# the solution's moves played so far
def sol.done(sol: Maybe<&2, List<&2, U32>>, +step: U32) -> List<&2, U32>:
  match sol:
    case Some{xs}:
      List.take(&2, U32, xs, U32.to_nat(step))
    case None{}:
      Nil{}

# where the cube is: the position, and the solution's moves played
def pos.now(+pos: List<&2, U32>, sol: Maybe<&2, List<&2, U32>>, +step: U32) -> List<&2, U32>:
  pos.simp(List.append(&2, U32, pos, sol.done(sol, step)))

def pos.solved(+ms: List<&2, U32>) -> Bool:
  C.cube.is_solved(C.cube.apply(ms, C.cube.solved()))

# Scrambles
# ---------

# Marsaglia's xorshift32
def rand.next(+x: U32) -> U32:
  +a = U32.xor(x, U32.shln(x, 13n))
  +b = U32.xor(a, U32.shrn(a, 17n))
  U32.xor(b, U32.shln(b, 5n))

# whether move m may follow a turn of face lf (6: none yet): never the same
# face twice, and a face and the one across in one order only (LAWS.bend:
# same_face_merge and opposite_commute make any other order no shorter)
def scr.allowed(+m: U32, +lf: U32) -> Bool:
  +f = U32.div(m, 3)
  Bool.and(U32.is_ne(f, lf), Bool.or(U32.is_ge(f, 3), U32.is_ne(U32.add(f, 3), lf)))

# n random moves, each allowed after the last (fuel bounds the draws)
def scr.gen(fuel: Nat, +n: Nat, +x: U32, +lf: U32, +acc: List<&2, U32>) -> List<&2, U32>:
  match fuel n:
    case _ 0n:
      List.reverse(&2, U32, acc)
    case 0n 1n+q:
      List.reverse(&2, U32, acc)
    case 1n+f 1n+q:
      +x2 = rand.next(x)
      +m = U32.mod(U32.shrn(x2, 7n), 18)
      +ok = scr.allowed(m, lf)
      scr.gen(f, Bool.pick(Nat, ok, q, 1n+q), x2, Bool.pick(U32, ok, U32.div(m, 3), lf),
        Bool.pick(List<&2, U32>, ok, m <> acc, acc))

# 12 to 16 moves: the solver answers those in seconds
def scr.of(+seed: U32) -> List<&2, U32>:
  +x = rand.next(rand.next(seed))
  scr.gen(400n, U32.to_nat(U32.add(12, U32.mod(x, 5))), x, 6, [])

# Effects
# -------

# animate move m in ms milliseconds, ending on the cube c
def turn.fx(+m: U32, +ms: U32, +c: C.Cube) -> W.Effect:
  W.Host{"turned", "turn", C.cube.name(m) ++ " " ++ U32.show(ms) ++ " " ++ C.cube.facelets(c)}

def show.fx(+c: C.Cube) -> W.Effect:
  W.Host{"shown", "show", C.cube.facelets(c)}

# ask the solver about the position, as request g
# (who: the page's name, so the solver knows a page's asks from another's)
# (the solver on this device, web/solver.js; where it cannot run, a quick
# two-phase way on this device, marked "quick", never a server: it is told the cube's stickers, the moves that make it, and the page's name,
# and tells each answer as the search goes, so it is asked once; and the
# position's own moves undone, a way back already known: so an answer is never
# longer, and the search proves the shortest once no shorter way is left)
def ask.fx(+pos: List<&2, U32>, +g: U32, +who: String) -> W.Effect:
  W.Host{"sol" ++ U32.show(g), "solve", C.cube.facelets(C.cube.apply(pos, C.cube.solved())) ++ " " ++ C.cube.nums(pos) ++ " " ++ who
    ++ " " ++ C.cube.nums(C.cube.inv(pos))}

# a second's tick while request g waits, and asking again after a "down"
def tick.fx(+g: U32) -> W.Effect:
  W.After{"tick" ++ U32.show(g), 1000}

def again.fx(+g: U32, +ms: U32) -> W.Effect:
  W.After{"again" ++ U32.show(g), ms}

# the solution's move at step i, if there is one
def sol.at(sol: Maybe<&2, List<&2, U32>>, +i: U32) -> Maybe<&2, U32>:
  match sol:
    case Some{xs}:
      List.get(&2, U32, xs, U32.to_nat(i))
    case None{}:
      None{}

def sol.len(sol: Maybe<&2, List<&2, U32>>) -> U32:
  match sol:
    case Some{xs}:
      U32.from_nat(List.length(&2, U32, xs))
    case None{}:
      0

# Updates
# -------

def next.go(nm: Maybe<&2, U32>, free: Bool, +s: S, +auto: Bool) -> S & List<&2, W.Effect>:
  match nm free s:
    case Some{+m} True{} S{cube, queue, busy, a, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      +c2 = C.cube.mul(cube, C.cube.move(m))
      (S{c2, queue, True{}, auto, pos, sol, U32.add(step, 1), False{}, info, bad, opt, gen, wait, who}, [turn.fx(m, 520, c2)])
    case _ _ S{cube, queue, busy, a, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, Bool.and(busy, Bool.or(a, auto)), pos, sol, step, asked, info, bad, opt, gen, wait, who}, [])

# Next step (auto: and the rest after it)
def on.next(+s: S, +auto: Bool) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, a, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      next.go(sol.at(sol, step), Bool.not(busy), s, auto)

# the turns are over: the solution's next if playing, else rest
def turned.rest(auto: Bool, +s: S) -> S & List<&2, W.Effect>:
  match auto:
    case True{}:
      on.next(s, True{})
    case False{}:
      (s, [])

# a turn is over: the next one waiting (a scramble's, or a hand's), or the
# solution's if playing, or rest
def turned.go(queue: List<&2, U32>, +s: S) -> S & List<&2, W.Effect>:
  match queue s:
    case Con{+m, rest} S{cube, q, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      +c2 = C.cube.mul(cube, C.cube.move(m))
      (S{c2, rest, True{}, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}, [turn.fx(m, 160, c2)])
    case Nil{} S{cube, q, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      turned.rest(auto, S{cube, Nil{}, False{}, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who})

def on.turned(+s: S) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      turned.go(queue, s)

# A hand's turn: the position is where the cube is, then m. The turn is
# animated now, or after the one in progress; a solution or a solve under
# way no longer applies (a newer request number drops its answer).
def hand.go(free: Bool, +s: S, +m: U32) -> S & List<&2, W.Effect>:
  match free s:
    case True{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      +c2 = C.cube.mul(cube, C.cube.move(m))
      (S{c2, Nil{}, True{}, False{}, pos.simp(List.append(&2, U32, pos.now(pos, sol, step), [m])), None{}, 0, False{}, "", False{}, True{}, U32.add(gen, 1), 0, who},
       [turn.fx(m, 200, c2)])
    case False{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, List.append(&2, U32, queue, [m]), True{}, False{}, pos.simp(List.append(&2, U32, pos.now(pos, sol, step), [m])), None{}, 0, False{}, "", False{}, True{}, U32.add(gen, 1), 0, who},
       [])

def on.turn(+s: S, +m: U32) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      hand.go(Bool.not(busy), s, m)

# Solve: the position the cube is in, asked about
def solve.go(no: Bool, home: Bool, +s: S) -> S & List<&2, W.Effect>:
  match no home s:
    case True{} _ S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (s, [])
    case False{} True{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, auto, Nil{}, None{}, 0, False{}, "It is solved already: nothing to do.", True{}, True{}, U32.add(gen, 1), 0, who}, [])
    case False{} False{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      +now = pos.now(pos, sol, step)
      +g = U32.add(gen, 1)
      (S{cube, queue, busy, False{}, now, None{}, 0, True{}, "", False{}, True{}, g, 0, who}, [ask.fx(now, g, who), tick.fx(g)])

def on.solve(+s: S) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      solve.go(asked, pos.solved(pos.now(pos, sol, step)), s)

def scramble.kick(+ms: List<&2, U32>, +gen: U32, +who: String) -> S & List<&2, W.Effect>:
  match ms:
    case Nil{}:
      (init.as(who), [])
    case Con{+m, +rest}:
      +c1 = C.cube.move(m)
      +g = U32.add(gen, 1)
      (S{c1, rest, True{}, False{}, ms, None{}, 0, True{}, "", False{}, True{}, g, 0, who},
       [show.fx(C.cube.solved()), turn.fx(m, 130, c1), ask.fx(ms, g, who), tick.fx(g)])

def scramble.go(no: Bool, +s: S, +seed: U32) -> S & List<&2, W.Effect>:
  match no s:
    case True{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (s, [])
    case False{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      scramble.kick(scr.of(seed), gen, who)

def on.scramble(+s: S, +seed: U32) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      scramble.go(busy, s, seed)

def reset.go(no: Bool, +s: S) -> S & List<&2, W.Effect>:
  match no s:
    case True{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (s, [])
    case False{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{C.cube.solved(), Nil{}, False{}, False{}, Nil{}, None{}, 0, False{}, "", False{}, True{}, U32.add(gen, 1), 0, who}, [show.fx(C.cube.solved())])

def on.reset(+s: S) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      reset.go(busy, s)

# 1234567 as "1,234,567"
def commas.go(s: String, +i: U32) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{+c, t}:
      +rest : String = SCon{c, commas.go(t, U32.add(i, 1))}
      Bool.pick(String, Bool.and(U32.is_zero(U32.mod(i, 3)), U32.is_ne(i, 0)), SCon{',', rest}, rest)

def commas(+n: U32) -> String:
  String.reverse(commas.go(String.reverse(U32.show(n)), 0))

# "83 ms", "1.3 s"
def took(+ms: U32) -> String:
  Bool.pick(String, U32.is_lt(ms, 1000), U32.show(ms) ++ " ms",
    U32.show(U32.div(ms, 1000)) ++ "." ++ U32.show(U32.div(U32.mod(ms, 1000), 100)) ++ " s")

# whether xs solves the cube pos makes: checked here too, by Cube.bend
def checks(m: Maybe<&2, List<&2, U32>>, +pos: List<&2, U32>) -> Bool:
  match m:
    case Some{xs}:
      C.cube.is_solved(C.cube.apply(xs, C.cube.apply(pos, C.cube.solved())))
    case None{}:
      False{}

# the solver's time limit for one cube, in seconds (Worker.bend's wk.limit)
def lim() -> U32:
  120

def plural(+n: U32, +one: String, +many: String) -> String:
  U32.show(n) ++ " " ++ Bool.pick(String, U32.is_eq(n, 1), one, many)

# "every way back shorter than b moves": what the search ruled out
def ruled(+b: U32) -> String:
  "every way back shorter than " ++ plural(b, "move", "moves") ++ " was ruled out"

def solved.go(m: Maybe<&2, List<&2, U32>>, good: Bool, +s: S, +say: String) -> S & List<&2, W.Effect>:
  match m good s:
    case Some{+xs} True{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, auto, pos, Some{xs}, 0, False{}, say, False{}, True{}, gen, wait, who}, [])
    case _ _ S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, auto, pos, None{}, 0, False{}, "The solver's answer did not check out.", True{}, True{}, gen, wait, who}, [])

# no shortest solution in time: the position's own moves undone instead (a
# way back, not the shortest; checked all the same), and how far the search
# got: every way back shorter than b moves was ruled out
def late.go(good: Bool, +s: S, +b: U32, +secs: String) -> S & List<&2, W.Effect>:
  match good s:
    case True{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, auto, pos, Some{C.cube.inv(pos)}, 0, False{},
         "It is your own moves undone. The search stopped after " ++ secs ++ ": " ++ ruled(b) ++ ".", False{}, False{}, gen, wait, who}, [])
    case False{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, auto, pos, None{}, 0, False{}, "No answer in " ++ secs ++ ".", True{}, True{}, gen, wait, who}, [])

# "down": no solver is there (one is starting: it reads its tables for about
# a minute); the request stays open and is asked again in 4 s, for 150 s
def down.go(more: Bool, +s: S) -> S & List<&2, W.Effect>:
  match more s:
    case True{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, auto, pos, None{}, 0, True{}, "warming", False{}, True{}, gen, wait, who}, [again.fx(gen, 4000)])
    case False{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, auto, pos, None{}, 0, False{}, "The solver did not come back in time. Press Solve again in a few minutes.", True{}, True{}, gen, wait, who}, [])

# What an answer is: a shortest solution (its moves); a short way back not
# proven the shortest ("short": the search stopped at its time limit;
# "working": it goes on); ask again ("queued": the solver is on other cubes
# first; "down": no solver answers, one is starting); or a word
type Ak is Data:
  ABest{}
  AShort{}
  AWork{}
  AQueued{}
  ADown{}
  ALate{}
  AQuick{}
  AWord{}

def ak.of(+w: String) -> Ak:
  Bool.pick(Ak, String.eq(w, "short"), AShort{},
  Bool.pick(Ak, String.eq(w, "working"), AWork{},
  Bool.pick(Ak, String.eq(w, "queued"), AQueued{},
  Bool.pick(Ak, String.eq(w, "down"), ADown{},
  Bool.pick(Ak, String.eq(w, "late"), ALate{},
  Bool.pick(Ak, String.eq(w, "quick"), AQuick{},
  Bool.pick(Ak, Bool.or(Bool.or(String.eq(w, "busy"), String.eq(w, "cancelled")), Bool.or(String.eq(w, "none"), String.eq(w, "nodevice"))), AWord{}, ABest{})))))))

# an answer without moves, said plainly
def word.say(+w: String) -> String:
  Bool.pick(String, String.eq(w, "busy"), "The solver is busy with other visitors' cubes. Press Solve again in a minute.",
  Bool.pick(String, String.eq(w, "cancelled"), "A newer solve from this page took this one's place.",
  Bool.pick(String, String.eq(w, "nodevice"), "This browser cannot run the solver here (it needs shared memory between its workers), and it could not work out a quick way either.",
    "The solver found no solution within 20 moves, which cannot happen. Please say so.")))

# how far the shortest search got (0: its tables are still on their way)
def so.far(+b: U32) -> String:
  Bool.pick(String, U32.is_zero(b), "Getting this device ready for the shortest search (its tables come once, then stay)...", "So far " ++ ruled(b) ++ ".")

# a short way back, not proven the shortest: the lines are the word, the
# nodes, the milliseconds since the cube was first asked for, "ok", the
# bound being searched, the moves, the time limit. Shown (checked here too,
# by Cube.bend); when the search stopped, the answer; while it goes on, the
# page asks again (and the server's search goes on, the same one)
def rough.go(final: Bool, good: Bool, +s: S, +xs: List<&2, U32>, +ls: List<&2, String>) -> S & List<&2, W.Effect>:
  match final good s:
    case True{} True{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, auto, pos, Some{xs}, 0, False{},
         "The search stopped after " ++ took(num(line(ls, 2n))) ++ ", so it may not be the shortest: " ++ ruled(num(line(ls, 4n))) ++ ".",
         False{}, False{}, gen, U32.div(num(line(ls, 2n)), 1000), who}, [])
    case False{} True{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, auto, pos, Some{xs}, 0, True{}, so.far(num(line(ls, 4n))),
         False{}, False{}, gen, U32.div(num(line(ls, 2n)), 1000), who}, [])
    case True{} False{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      late.go(checks(Some{C.cube.inv(pos)}, pos), s, num(line(ls, 4n)), took(num(line(ls, 2n))))
    case False{} False{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (s, [])

def rough(+final: Bool, +s: S, +ls: List<&2, String>) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      +m = C.cube.read(line(ls, 5n))
      rough.go(final, Bool.and(String.eq(line(ls, 3n), "ok"), checks(m, pos)), s, Maybe.default(&2, List<&2, U32>, m, Nil{}), ls)

# "queued": the solver is on other cubes first; asked again at once (the ask
# waits there up to 20 s)
def queued.go(+s: S) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, auto, pos, sol, step, True{}, "queued", False{}, opt, gen, wait, who}, [])

# where an answer was found: the device's line
def found.at(+w: String) -> String:
  Bool.pick(String, String.is_empty(w), "on this device", w)

# "quick": this browser cannot run the shortest search (no shared memory
# between workers), so a two-phase way was worked out on this device alone:
# the lines are the word, 0, the milliseconds, "ok", 0, the moves. Checked
# here too, by Cube.bend; never called the shortest
def quick.go(m: Maybe<&2, List<&2, U32>>, good: Bool, +s: S, +ms: U32) -> S & List<&2, W.Effect>:
  match m good s:
    case Some{+xs} True{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, auto, pos, Some{xs}, 0, False{},
         "A quick way, worked out on this device in " ++ took(ms) ++ ". It may not be the shortest: this browser cannot run the shortest search (it needs shared memory between its workers).",
         False{}, False{}, gen, wait, who}, [])
    case _ _ S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, auto, pos, None{}, 0, False{}, "The quick way did not check out.", True{}, True{}, gen, wait, who}, [])

def answer.go(k: Ak, +s: S, +ls: List<&2, String>) -> S & List<&2, W.Effect>:
  match k s:
    case ABest{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      +m = C.cube.read(line(ls, 0n))
      +good = Bool.and(String.eq(line(ls, 3n), "ok"), checks(m, pos))
      solved.go(m, good, s, commas(num(line(ls, 1n))) ++ " positions searched in " ++ took(num(line(ls, 2n))) ++ ", " ++ found.at(line(ls, 4n)))
    case AShort{} _:
      rough(True{}, s, ls)
    case AWork{} _:
      rough(False{}, s, ls)
    case AQueued{} _:
      queued.go(s)
    case ADown{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      down.go(U32.is_lt(wait, 150), s)
    case ALate{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      late.go(checks(Some{C.cube.inv(pos)}, pos), s, num(line(ls, 4n)), took(num(line(ls, 2n))))
    case AQuick{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      +m = C.cube.read(line(ls, 5n))
      quick.go(m, Bool.and(String.eq(line(ls, 3n), "ok"), checks(m, pos)), s, num(line(ls, 2n)))
    case AWord{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, auto, pos, None{}, 0, False{}, word.say(line(ls, 0n)), True{}, True{}, gen, wait, who}, [])

def answer.if(fresh: Bool, +s: S, +body: String) -> S & List<&2, W.Effect>:
  match fresh:
    case False{}:
      (s, [])
    case True{}:
      +ls = String.split(body, '\n')
      answer.go(ak.of(line(ls, 0n)), s, ls)

# the solver's answer (Ak); only the last request's counts
def on.solved(+s: S, +g: U32, +body: String) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      answer.if(Bool.and(asked, U32.is_eq(g, gen)), s, body)

def failed.if(fresh: Bool, +s: S) -> S & List<&2, W.Effect>:
  match fresh s:
    case False{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (s, [])
    case True{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      down.go(U32.is_lt(wait, 150), s)

def on.failed(+s: S, +g: U32) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      failed.if(Bool.and(asked, U32.is_eq(g, gen)), s)

# a second more of waiting for request g, if it is still the one waited for
def tick.if(fresh: Bool, +s: S) -> S & List<&2, W.Effect>:
  match fresh s:
    case True{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, U32.add(wait, 1), who}, [tick.fx(gen)])
    case False{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (s, [])

def on.tick(+s: S, +g: U32) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      tick.if(Bool.and(asked, U32.is_eq(g, gen)), s)

# ask again for request g after a "down", if it is still the one waited for
def again.if(fresh: Bool, +s: S) -> S & List<&2, W.Effect>:
  match fresh s:
    case True{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (s, [ask.fx(pos, gen, who)])
    case False{} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (s, [])

def on.again(+s: S, +g: U32) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      again.if(Bool.and(asked, U32.is_eq(g, gen)), s)

# the page opened: its name for the solver, from the time it opened
def on.start(+s: S, +seed: U32) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, "w" ++ U32.show(seed)}, [show.fx(C.cube.solved()), W.Route{"route"}])

# A link from another device: "/#m=3.10.17" (the fragment, so it never reaches
# a server) is that position; it is shown and solved at once
def route.moves(+v: String) -> Maybe<&2, List<&2, U32>>:
  +f = line(String.split(v, '#'), 1n)
  Bool.pick(Maybe<&2, List<&2, U32>>, String.starts_with(f, "m="), C.cube.read(String.drop(f, 2n)), None{})

def route.go(m: Maybe<&2, List<&2, U32>>, +s: S) -> S & List<&2, W.Effect>:
  match m s:
    case Some{+ms} S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      +p = pos.simp(ms)
      +c = C.cube.apply(p, C.cube.solved())
      +g = U32.add(gen, 1)
      Bool.pick(S & List<&2, W.Effect>, pos.solved(p), (s, []),
        (S{c, Nil{}, False{}, False{}, p, None{}, 0, True{}, "", False{}, True{}, g, 0, who}, [show.fx(c), ask.fx(p, g, who), tick.fx(g)]))
    case None{} _:
      (s, [])

# the hand-off link, for another device
def handoff.path(+pos: List<&2, U32>) -> String:
  "/#m=" ++ C.cube.nums(pos)

def on.copy(+s: S) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      (s, [W.Host{"copied", "copy", handoff.path(pos)}])

def on.route(+s: S, +v: String) -> S & List<&2, W.Effect>:
  route.go(route.moves(v), s)

def apply(+s: S, m: Msg) -> S & List<&2, W.Effect>:
  match m:
    case MStart{seed}:
      on.start(s, seed)
    case MRoute{v}:
      on.route(s, v)
    case MCopy{}:
      on.copy(s)
    case MHow{}:
      (s, [W.Host{"howto:shown", "howto", ""}])
    case MOwn{}:
      (s, [W.Host{"own:shown", "own", ""}])
    case MCol{}:
      (s, [W.Host{"colors:shown", "colors", ""}])
    case MScramble{seed}:
      on.scramble(s, seed)
    case MTurn{+t}:
      on.turn(s, t)
    case MSolve{}:
      on.solve(s)
    case MNext{}:
      on.next(s, False{})
    case MPlay{}:
      on.next(s, True{})
    case MReset{}:
      on.reset(s)
    case MTurned{}:
      on.turned(s)
    case MSolved{g, v}:
      on.solved(s, g, v)
    case MFailed{g}:
      on.failed(s, g)
    case MTick{g}:
      on.tick(s, g)
    case MAgain{g}:
      on.again(s, g)
    case MOther{}:
      (s, [])

def update(s: S, i: W.Input) -> S & List<&2, W.Effect>:
  match i:
    case W.Input{+at, +tag, +v}:
      apply(s, msg.of(at, tag, v))

# The view
# --------

def prop.on(+name: String, on: Bool) -> W.Attr:
  W.Prop{name, Bool.pick(String, on, "true", "false")}

# a move as a tile: its face's letter, its turn, its face's color (CSS)
def tile.kind(+i: U32, +step: U32) -> String:
  Bool.pick(String, U32.is_lt(i, step), "tile done", Bool.pick(String, U32.is_eq(i, step), "tile now", "tile"))

def tile(+i: U32, +step: U32, +m: U32) -> W.Html:
  +name = C.cube.name(m)
  W.keyed("li", U32.show(i) ++ ":" ++ name, [W.cls(tile.kind(i, step)), W.Prop{"data-face", String.take(name, 1n)}, W.Prop{"style", "--i:" ++ U32.show(i)}],
    [W.el("span", [W.cls("tile-n")], [W.text(U32.show(U32.add(i, 1)))]),
     W.el("span", [W.cls("tile-m")], [W.text(name)])])

def tiles(xs: List<&2, U32>, +i: U32, +step: U32) -> List<&2, W.Html>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+m, t}:
      tile(i, step, m) <> tiles(t, U32.add(i, 1), step)

def strip(sol: Maybe<&2, List<&2, U32>>, +step: U32, +opt: Bool) -> W.Html:
  match sol:
    case Some{xs}:
      W.el("ol", [W.cls(Bool.pick(String, opt, "strip", "strip rough")), W.Prop{"aria-label", "the solution, move by move"}], tiles(xs, 0, step))
    case None{}:
      W.el("ol", [W.cls("strip empty")], [])

# The hand's buttons: a row for each kind of turn, a column for each face
def pad.btn(+m: U32, +ok: Bool) -> W.Html:
  +name = C.cube.name(m)
  W.el("button", [W.Prop{"id", "t" ++ U32.show(m)}, W.cls("turn"), W.Prop{"data-face", String.take(name, 1n)},
                  W.Prop{"aria-label", "turn " ++ name}, prop.on("disabled", Bool.not(ok)), W.On{"click", "t" ++ U32.show(m)}],
    [W.text(name)])

# the turns k, k + 3, .. (one per face), from face f on
def pad.row(n: Nat, +m: U32, +ok: Bool) -> List<&2, W.Html>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      pad.btn(m, ok) <> pad.row(p, U32.add(m, 3), ok)

def pad(+ok: Bool) -> W.Html:
  W.el("div", [W.cls("pad"), W.Prop{"role", "group"}, W.Prop{"aria-label", "turn a face yourself"}],
    List.append(&2, W.Html, pad.row(6n, 0, ok), List.append(&2, W.Html, pad.row(6n, 2, ok), pad.row(6n, 1, ok))))

# the headline: where things stand
def status.solved(+n: U32, +step: U32, +opt: Bool, +asked: Bool, +info: String, +wait: U32) -> String:
  Bool.pick(String, asked,
    "A short way back: " ++ plural(n, "move", "moves") ++ " so far. Still looking for the shortest... " ++ U32.show(wait) ++ " s of " ++ U32.show(lim()) ++ " s. " ++ info,
  Bool.pick(String, U32.is_zero(n), "That position was solved already.",
    Bool.pick(String, U32.is_ge(step, n), Bool.pick(String, opt, "Solved, in " ++ plural(n, "move", "moves") ++ ". No shorter way exists.", "Solved, in " ++ plural(n, "move", "moves") ++ "."),
      Bool.pick(String, opt, "Optimal: " ++ plural(n, "move", "moves") ++ ". Every shorter sequence was ruled out.",
        "A short way back: " ++ plural(n, "move", "moves") ++ ". " ++ info))))

def status.idle(+n: U32) -> String:
  Bool.pick(String, U32.is_zero(n), "A solved cube. Scramble it, or turn its faces yourself with the buttons, then press Solve.",
    "Your position: " ++ plural(n, "move", "moves") ++ " from solved. Press Solve for the shortest way back.")

# while a solve is asked: how long it has waited, so a long one looks alive
def status.asked(+busy: Bool, +warming: Bool, +queued: Bool, +wait: U32) -> String:
  Bool.pick(String, queued, "Waiting: the solver is on other visitors' cubes first... " ++ U32.show(wait) ++ " s",
  Bool.pick(String, warming, "The solver is starting up (it reads its tables, about a minute); asking again... " ++ U32.show(wait) ++ " s",
    Bool.pick(String, busy, "Scrambling... and already searching.",
      "Searching every sequence, shortest first... " ++ U32.show(wait) ++ " s (" ++ U32.show(lim()) ++ " s at most)")))

def status(+s: S) -> String:
  match s:
    case S{cube, queue, busy, auto, pos, Some{xs}, step, asked, info, bad, opt, gen, wait, who}:
      status.solved(U32.from_nat(List.length(&2, U32, xs)), step, opt, asked, info, wait)
    case S{cube, queue, busy, auto, pos, None{}, step, asked, info, bad, opt, gen, wait, who}:
      Bool.pick(String, bad, info,
        Bool.pick(String, asked, status.asked(busy, String.eq(info, "warming"), String.eq(info, "queued"), wait),
          status.idle(U32.from_nat(List.length(&2, U32, pos)))))

def fact(+k: String, +v: String) -> W.Html:
  W.el("div", [W.cls("fact")], [W.el("dt", [], [W.text(k)]), W.el("dd", [], [W.text(v)])])

def facts(+s: S) -> W.Html:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      +n = sol.len(sol)
      +has = Maybe.is_some(&2, List<&2, U32>, sol)
      W.el("dl", [W.cls("facts")],
        [fact("position", plural(U32.from_nat(List.length(&2, U32, pos)), "move", "moves")),
         fact(Bool.pick(String, opt, "shortest solution", "a solution"), Bool.pick(String, has, plural(n, "move", "moves"), "-")),
         fact("done", U32.show(Bool.pick(U32, U32.is_lt(step, n), step, n)) ++ " / " ++ U32.show(n)),
         fact("search", Bool.pick(String, has, Bool.pick(String, opt, info, Bool.pick(String, asked, "still searching", Bool.pick(String, String.starts_with(info, "A quick way"), "quick way only", "stopped at " ++ U32.show(lim()) ++ " s"))), "-"))])

def next.name(m: Maybe<&2, U32>) -> String:
  match m:
    case Some{+x}:
      C.cube.name(x)
    case None{}:
      ""

def next.label(+s: S) -> String:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      next.name(sol.at(sol, step))

# when this device could not prove a shortest way (time up, or it cannot run
# the solver): a link to the same position for a bigger one (a laptop, an iPad)
def handoff(+on: Bool, +pos: List<&2, U32>) -> W.Html:
  +path = handoff.path(pos)
  Bool.pick(W.Html, on,
    W.el("div", [W.cls("handoff"), W.Prop{"role", "note"}],
      [W.el("p", [], [W.text("This device could not prove a shortest way in time. A bigger one (a laptop, or an iPad) may: open this link there, and it solves the same cube.")]),
       W.el("p", [W.cls("handoff-row")],
         [W.el("a", [W.Prop{"id", "handoff-link"}, W.Prop{"href", path}], [W.text("elcubodeedgar.hhefesto.dev" ++ path)]),
          W.el("button", [W.Prop{"id", "copy"}, W.cls("btn"), W.On{"click", "copy"}], [W.text("Copy the link")])])]),
    W.el("div", [W.cls("handoff none")], []))

# "Enter your own cube": a card of its own under the main buttons, where a
# visitor with a real cube in hand sees it first (index.html's .own-cta): a
# small scrambled face, what it does, and an arrow; it opens own.js's panel
def own.st(+f: String) -> W.Html:
  W.el("span", [W.cls("own-cta-st"), W.Prop{"data-face", f}], [])

def own.cta() -> W.Html:
  W.el("button", [W.Prop{"id", "own"}, W.cls("own-cta"), W.Prop{"type", "button"}, W.On{"click", "own"}],
    [W.el("span", [W.cls("own-cta-cube"), W.Prop{"aria-hidden", "true"}],
       [own.st("R"), own.st("D"), own.st("B"), own.st("U"), own.st("F"), own.st("L"), own.st("F"), own.st("R"), own.st("D")]),
     W.el("span", [W.cls("own-cta-text")],
       [W.el("span", [W.cls("own-cta-k")], [W.text("Got a real one?")]),
        W.el("span", [W.cls("own-cta-t")], [W.text("Enter your own cube")]),
        W.el("span", [W.cls("own-cta-s")], [W.text("Paint its colors or use the camera, and get its shortest way back.")])]),
     W.el("span", [W.cls("own-cta-go"), W.Prop{"aria-hidden", "true"}], [])])

# "Your cube's colors": a row under it, for a cube whose colors are not the
# page's (web/colors.js's picker; Scheme.bend's presets): the six centers
# on a net, in the colors the page now has, and the scheme's name (index.html
# puts it in, from --sch-name)
def col.f(+f: String) -> W.Html:
  W.el("i", [W.Prop{"data-f", f}], [])

def col.row() -> W.Html:
  W.el("button", [W.Prop{"id", "colors"}, W.cls("sch-row"), W.Prop{"type", "button"}, W.On{"click", "colors"}],
    [W.el("span", [W.cls("sch-net sch-live"), W.Prop{"aria-hidden", "true"}],
       [col.f("U"), col.f("R"), col.f("F"), col.f("D"), col.f("L"), col.f("B")]),
     W.el("span", [W.cls("sch-txt")],
       [W.el("span", [W.cls("sch-k")], [W.text("Your cube's colors")]),
        W.el("span", [W.cls("sch-name")], [])]),
     W.el("span", [W.cls("sch-go")], [W.text("Not these? Change")])])

def view.go(+s: S) -> W.Html:
  match s:
    case S{cube, queue, busy, auto, pos, sol, step, asked, info, bad, opt, gen, wait, who}:
      +can = Bool.and(Bool.not(busy), Maybe.is_some(&2, U32, sol.at(sol, step)))
      +now = pos.now(pos, sol, step)
      +rough = Bool.and(Maybe.is_some(&2, List<&2, U32>, sol), Bool.not(opt))
      +off = Bool.and(Bool.and(Bool.not(asked), Bool.not(List.is_empty(&2, U32, pos))), Bool.or(rough, String.starts_with(info, "This browser cannot")))
      W.el("div", [W.cls("app" ++ Bool.pick(String, bad, " bad", "") ++ Bool.pick(String, asked, " searching", "") ++ Bool.pick(String, busy, " busy", ""))],
        [W.el("p", [W.cls("status"), W.Prop{"aria-live", "polite"}], [W.text(status(s))]),
         W.el("div", [W.cls("controls")],
           [W.el("button", [W.Prop{"id", "scramble"}, W.cls("btn primary"), prop.on("disabled", busy), W.On{"click", "scramble"}],
              [W.text("Scramble")]),
            W.el("button", [W.Prop{"id", "solve"}, W.cls("btn solve"), prop.on("disabled", Bool.or(asked, List.is_empty(&2, U32, now))), W.On{"click", "solve"}],
              [W.text("Solve")]),
            W.el("button", [W.Prop{"id", "reset"}, W.cls("btn ghost"), prop.on("disabled", Bool.or(busy, Bool.and(List.is_empty(&2, U32, now), Bool.not(asked)))), W.On{"click", "reset"}],
              [W.text("Reset")])]),
         own.cta(),
         col.row(),
         pad(True{}),
         W.el("p", [W.cls("pad-help")], [W.el("button", [W.Prop{"id", "howto"}, W.cls("howto"), W.On{"click", "howto"}], [W.text("What do these buttons mean?")])]),
         strip(sol, step, opt),
         handoff(off, pos),
         W.el("div", [W.cls("controls")],
           [W.el("button", [W.Prop{"id", "next"}, W.cls("btn"), prop.on("disabled", Bool.not(can)), W.On{"click", "next"}],
              [W.text("Next step"), W.el("span", [W.cls("btn-move")], [W.text(next.label(s))])]),
            W.el("button", [W.Prop{"id", "play"}, W.cls("btn ghost"), prop.on("disabled", Bool.not(can)), W.On{"click", "play"}],
              [W.text("Play to the end")])]),
         facts(s),
         W.el("p", [W.cls("scr")], [W.el("span", [W.cls("scr-k")], [W.text("position ")]), W.text(C.cube.show(pos))])])

def view(s: S) -> W.Html:
  view.go(s)

def step(s: S, i: W.Input) -> S & W.Out:
  W.app.step(~S, ~update, ~view, s, i)
