import Base
import ../bend-frp/Frp.bend as F
import ../bend-frp/Web.bend as W
import ../Cube.bend as C

# Edgar's Rubik's cube: the page. A bend-frp app (Web.bend): every state is a
# fold of the page's inputs, and the view a function of the state.
#
# The cube itself lives here, as Cube.bend's group element: a turn is shown by
# handing the 3D view (cube3d.js, the host's "turn") the move to animate and
# the 54 stickers the cube has after it; the view draws nothing of its own.
#
#   Scramble    a random scramble from solved, animated; at once the server
#               is asked for a shortest solution (GET /api/solve)
#   Next step   the solution's next move, animated
#   Play        every move left, one after the other

type S is Data:
  S{+cube: C.Cube, +queue: List<&2, U32>, +busy: Bool, +auto: Bool, +scr: List<&2, U32>,
    +sol: Maybe<&2, List<&2, U32>>, +step: U32, +asked: Bool, +info: String, +bad: Bool}

def init() -> S:
  S{C.cube.solved(), [], False{}, False{}, [], None{}, 0, False{}, "", False{}}

# What an input means
type Msg is Data:
  MStart{}
  MScramble{+seed: U32}
  MNext{}
  MPlay{}
  MTurned{}
  MSolved{+body: String}
  MFailed{+why: String}
  MOther{}

def msg.pick(st: Bool, sc: Bool, nx: Bool, pl: Bool, tu: Bool, so: Bool, fa: Bool, +seed: U32, +v: String) -> Msg:
  match st sc nx pl tu so fa:
    case True{} _ _ _ _ _ _:
      MStart{}
    case False{} True{} _ _ _ _ _:
      MScramble{seed}
    case False{} False{} True{} _ _ _ _:
      MNext{}
    case False{} False{} False{} True{} _ _ _:
      MPlay{}
    case False{} False{} False{} False{} True{} _ _:
      MTurned{}
    case False{} False{} False{} False{} False{} True{} _:
      MSolved{v}
    case False{} False{} False{} False{} False{} False{} True{}:
      MFailed{v}
    case False{} False{} False{} False{} False{} False{} False{}:
      MOther{}

# The input's time, as a seed: inputs never share a time (bend-frp's
# time_after), so two scrambles never share one
def seed.of(+t: F.Time) -> U32:
  match t:
    case F.Time{sec, frac}:
      U32.or(U32.xor(U32.mul(sec, 2654435761), frac), 1)

def msg.of(+t: F.Time, +tag: String, +v: String) -> Msg:
  msg.pick(String.eq(tag, "start"), String.eq(tag, "scramble"), String.eq(tag, "next"), String.eq(tag, "play"),
           String.eq(tag, "turned"), String.eq(tag, "solved"), String.eq(tag, "solved:failed"), seed.of(t), v)

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
  Bool.and(U32.is_ne(f, lf), U32.is_ne(U32.add(f, 3), lf))

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

# 12 to 14 moves: the server answers those in seconds (15 can take minutes)
def scr.of(+seed: U32) -> List<&2, U32>:
  +x = rand.next(rand.next(seed))
  scr.gen(400n, U32.to_nat(U32.add(12, U32.mod(x, 3))), x, 6, [])

# Effects
# -------

# animate move m in ms milliseconds, ending on the cube c
def turn.fx(+m: U32, +ms: U32, +c: C.Cube) -> W.Effect:
  W.Host{"turned", "turn", C.cube.name(m) ++ " " ++ U32.show(ms) ++ " " ++ C.cube.facelets(c)}

def show.fx(+c: C.Cube) -> W.Effect:
  W.Host{"shown", "show", C.cube.facelets(c)}

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
    case Some{+m} True{} S{cube, queue, busy, a, scr, sol, step, asked, info, bad}:
      +c2 = C.cube.mul(cube, C.cube.move(m))
      (S{c2, queue, True{}, auto, scr, sol, U32.add(step, 1), asked, info, bad}, [turn.fx(m, 520, c2)])
    case _ _ S{cube, queue, busy, a, scr, sol, step, asked, info, bad}:
      (S{cube, queue, busy, Bool.and(busy, Bool.or(a, auto)), scr, sol, step, asked, info, bad}, [])

# Next step (auto: and the rest after it)
def on.next(+s: S, +auto: Bool) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, a, scr, sol, step, asked, info, bad}:
      next.go(sol.at(sol, step), Bool.not(busy), s, auto)

# the turns are over: the solution's next if playing, else rest
def turned.rest(auto: Bool, +s: S) -> S & List<&2, W.Effect>:
  match auto:
    case True{}:
      on.next(s, True{})
    case False{}:
      (s, [])

# a turn is over: the scramble's next, or the solution's if playing, or rest
def turned.go(queue: List<&2, U32>, +s: S) -> S & List<&2, W.Effect>:
  match queue s:
    case Con{+m, rest} S{cube, q, busy, auto, scr, sol, step, asked, info, bad}:
      +c2 = C.cube.mul(cube, C.cube.move(m))
      (S{c2, rest, True{}, auto, scr, sol, step, asked, info, bad}, [turn.fx(m, 130, c2)])
    case Nil{} S{cube, q, busy, auto, scr, sol, step, asked, info, bad}:
      turned.rest(auto, S{cube, Nil{}, False{}, auto, scr, sol, step, asked, info, bad})

def on.turned(+s: S) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, scr, sol, step, asked, info, bad}:
      turned.go(queue, s)

def scramble.kick(+ms: List<&2, U32>) -> S & List<&2, W.Effect>:
  match ms:
    case Nil{}:
      (init(), [])
    case Con{+m, +rest}:
      +c1 = C.cube.move(m)
      (S{c1, rest, True{}, False{}, ms, None{}, 0, True{}, "", False{}},
       [show.fx(C.cube.solved()), turn.fx(m, 130, c1), W.Http{"solved", "GET", "/api/solve?m=" ++ C.cube.nums(ms), ""}])

def scramble.go(no: Bool, +s: S, +seed: U32) -> S & List<&2, W.Effect>:
  match no:
    case True{}:
      (s, [])
    case False{}:
      scramble.kick(scr.of(seed))

def on.scramble(+s: S, +seed: U32) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, scr, sol, step, asked, info, bad}:
      scramble.go(Bool.or(busy, asked), s, seed)

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

def line(+ls: List<&2, String>, +i: Nat) -> String:
  Maybe.default(&2, String, List.get(&2, String, ls, i), "")

def num(+s: String) -> U32:
  Maybe.default(&2, U32, U32.read(s), 0)

# "83 ms", "1.3 s"
def took(+ms: U32) -> String:
  Bool.pick(String, U32.is_lt(ms, 1000), U32.show(ms) ++ " ms",
    U32.show(U32.div(ms, 1000)) ++ "." ++ U32.show(U32.div(U32.mod(ms, 1000), 100)) ++ " s")

def solved.go(m: Maybe<&2, List<&2, U32>>, good: Bool, +s: S, +say: String) -> S & List<&2, W.Effect>:
  match m good s:
    case Some{+xs} True{} S{cube, queue, busy, auto, scr, sol, step, asked, info, bad}:
      (S{cube, queue, busy, auto, scr, Some{xs}, 0, False{}, say, False{}}, [])
    case _ _ S{cube, queue, busy, auto, scr, sol, step, asked, info, bad}:
      (S{cube, queue, busy, auto, scr, None{}, 0, False{}, "The solver's answer did not check out.", True{}}, [])

# whether xs solves the cube scr makes: checked here too, by Cube.bend
def checks(m: Maybe<&2, List<&2, U32>>, +scr: List<&2, U32>) -> Bool:
  match m:
    case Some{xs}:
      C.cube.is_solved(C.cube.apply(xs, C.cube.apply(scr, C.cube.solved())))
    case None{}:
      False{}

# the server's four lines: moves, nodes, milliseconds, "ok"
def on.solved(+s: S, +body: String) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, scr, sol, step, asked, info, bad}:
      +ls = String.split(body, '\n')
      +m = C.cube.read(line(ls, 0n))
      +good = Bool.and(String.eq(line(ls, 3n), "ok"), checks(m, scr))
      solved.go(m, good, s, commas(num(line(ls, 1n))) ++ " positions searched in " ++ took(num(line(ls, 2n))) ++ ", on 8 cores")

def on.failed(+s: S) -> S & List<&2, W.Effect>:
  match s:
    case S{cube, queue, busy, auto, scr, sol, step, asked, info, bad}:
      (S{cube, queue, busy, auto, scr, None{}, 0, False{}, "The solver did not answer: it may be starting up (about a minute). Scramble again soon.", True{}}, [])

def apply(+s: S, m: Msg) -> S & List<&2, W.Effect>:
  match m:
    case MStart{}:
      (s, [show.fx(C.cube.solved())])
    case MScramble{seed}:
      on.scramble(s, seed)
    case MNext{}:
      on.next(s, False{})
    case MPlay{}:
      on.next(s, True{})
    case MTurned{}:
      on.turned(s)
    case MSolved{v}:
      on.solved(s, v)
    case MFailed{v}:
      on.failed(s)
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

def strip(sol: Maybe<&2, List<&2, U32>>, +step: U32) -> W.Html:
  match sol:
    case Some{xs}:
      W.el("ol", [W.cls("strip"), W.Prop{"aria-label", "the solution, move by move"}], tiles(xs, 0, step))
    case None{}:
      W.el("ol", [W.cls("strip empty")], [])

def plural(+n: U32, +one: String, +many: String) -> String:
  U32.show(n) ++ " " ++ Bool.pick(String, U32.is_eq(n, 1), one, many)

# the headline: where things stand
def status.solved(+n: U32, +step: U32, +info: String, +scr: U32) -> String:
  Bool.pick(String, U32.is_zero(n), "That scramble undid itself: the cube is solved.",
    Bool.pick(String, U32.is_ge(step, n), "Solved, in " ++ plural(n, "move", "moves") ++ ". No shorter way exists.",
      "Optimal: " ++ plural(n, "move", "moves") ++ ". Every shorter sequence was ruled out."))

def status(+s: S) -> String:
  match s:
    case S{cube, queue, busy, auto, scr, Some{xs}, step, asked, info, bad}:
      status.solved(U32.from_nat(List.length(&2, U32, xs)), step, info, 0)
    case S{cube, queue, busy, auto, scr, None{}, step, asked, info, bad}:
      Bool.pick(String, bad, info,
        Bool.pick(String, asked, Bool.pick(String, busy, "Scrambling... and already searching.", "Searching every sequence, shortest first..."),
          "A solved cube. Scramble it: the solver finds the shortest way back."))

def fact(+k: String, +v: String) -> W.Html:
  W.el("div", [W.cls("fact")], [W.el("dt", [], [W.text(k)]), W.el("dd", [], [W.text(v)])])

def facts(+s: S) -> W.Html:
  match s:
    case S{cube, queue, busy, auto, scr, sol, step, asked, info, bad}:
      +n = sol.len(sol)
      W.el("dl", [W.cls("facts")],
        [fact("scramble", plural(U32.from_nat(List.length(&2, U32, scr)), "move", "moves")),
         fact("shortest solution", Bool.pick(String, Maybe.is_some(&2, List<&2, U32>, sol), plural(n, "move", "moves"), "-")),
         fact("done", U32.show(Bool.pick(U32, U32.is_lt(step, n), step, n)) ++ " / " ++ U32.show(n)),
         fact("search", Bool.pick(String, Maybe.is_some(&2, List<&2, U32>, sol), info, "-"))])

def next.name(m: Maybe<&2, U32>) -> String:
  match m:
    case Some{+x}:
      C.cube.name(x)
    case None{}:
      ""

def next.label(+s: S) -> String:
  match s:
    case S{cube, queue, busy, auto, scr, sol, step, asked, info, bad}:
      next.name(sol.at(sol, step))

def view.go(+s: S) -> W.Html:
  match s:
    case S{cube, queue, busy, auto, scr, sol, step, asked, info, bad}:
      +can = Bool.and(Bool.not(busy), Maybe.is_some(&2, U32, sol.at(sol, step)))
      W.el("div", [W.cls("app" ++ Bool.pick(String, bad, " bad", "") ++ Bool.pick(String, asked, " searching", "") ++ Bool.pick(String, busy, " busy", ""))],
        [W.el("p", [W.cls("status"), W.Prop{"aria-live", "polite"}], [W.text(status(s))]),
         W.el("div", [W.cls("controls")],
           [W.el("button", [W.Prop{"id", "scramble"}, W.cls("btn primary"), prop.on("disabled", Bool.or(busy, asked)), W.On{"click", "scramble"}],
              [W.text("Scramble")]),
            W.el("button", [W.Prop{"id", "next"}, W.cls("btn"), prop.on("disabled", Bool.not(can)), W.On{"click", "next"}],
              [W.text("Next step"), W.el("span", [W.cls("btn-move")], [W.text(next.label(s))])]),
            W.el("button", [W.Prop{"id", "play"}, W.cls("btn ghost"), prop.on("disabled", Bool.not(can)), W.On{"click", "play"}],
              [W.text("Play to the end")])]),
         strip(sol, step),
         facts(s),
         W.el("p", [W.cls("scr")], [W.el("span", [W.cls("scr-k")], [W.text("scramble ")]), W.text(C.cube.show(scr))])])

def view(s: S) -> W.Html:
  view.go(s)

def step(s: S, i: W.Input) -> S & W.Out:
  W.app.step(~S, ~update, ~view, s, i)
