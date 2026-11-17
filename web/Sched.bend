import Base

# What the device's workers do for a cube, and what the page is told: a
# state machine the page's thin JS (web/solver.js) feeds with what happens,
# and whose commands it carries out. The workers run Dev.bend.
#
#   events (words joined by spaces; a move list is "3.10.17", "" for none):
#     start NOW CORES NP FACELETS LIMIT
#                                   a cube to solve (the same again: rejoin);
#                                   NP: how many prefixes a split bound has;
#                                   LIMIT: its time limit, ms (0: none; left
#                                   out: sc.limit()). The same cube with 0,
#                                   once it stopped at its limit: it goes on
#     h NOW B                       the cube's bound (Korf's tables)
#     two NOW WORD MOVES N          a two-phase answer (WORD: ok, none)
#     res NOW B WORD MOVES NODES    a bound's (or a subtree of it's) search
#     tick NOW                      the clock
#   commands (one a line):
#     job two A | job h | job bound B | job subs B
#                                   for any free worker (subs: one job a
#                                   prefix, Dev.bend's dv.prefixes(3))
#     say TEXT                      an answer for the page ('|' for a new line)
#     end                           the last answer said: nothing more to do
#     stop                          drop every job not done
#
# The answers, in the server's own form (Worker.bend), so the page reads
# both alike: a shortest solution (its moves, the nodes, the milliseconds,
# "ok", where it was found); "working" (the short way so far) or "short"
# (the time is up): the word, the nodes, the milliseconds, "ok", the bound
# being searched, the moves, the limit; "late" if the time is up with no
# way known at all.
#
# A solution is said to be a shortest one only when it is: found at bound b
# with every bound below b searched in full, or the short way itself once
# every bound below its length is.
#
# Every def is prefixed `sc.`.

# the time a cube gets, in ms (the user, 11-16: 240 s, not 120), unless the
# page asks for none (its "No time limit", the user, 11-16)
def sc.limit() -> Nat:
  240000n

# bounds from this one are split over the workers, a job a prefix
def sc.split() -> U32:
  11

# The state: the cube (its facelets), whether it runs, the bound being
# searched, the short way known (its moves, its length; 99 if none), the
# jobs of the bound not done, the nodes, when it began, when the page was
# last told, the cores, the last answer said and whose, its time limit (ms;
# 0: none, the page's "No time limit")
type Sc is Data:
  Sc{+key: String, +run: Bool, +b: U32, +short: String, +cap: U32, +left: U32, +nodes: U32,
     +t0: Nat, +said: Nat, +cores: U32, +last: String, +np: U32, +lim: Nat}

def sc.init() -> Sc:
  Sc{"", False{}, 0, "", 99, 0, 0, 0n, 0n, 1, "", 0, sc.limit()}

def sc.word(+ws: List<&2, String>, +i: Nat) -> String:
  Maybe.default(&2, String, List.get(&2, String, ws, i), "")

def sc.num(+s: String) -> U32:
  Maybe.default(&2, U32, U32.read(s), 0)

def sc.nat(+s: String) -> Nat:
  Maybe.default(&2, Nat, Nat.read(s), 0n)

# Answers
# -------

def sc.where(+cores: U32) -> String:
  "on " ++ U32.show(cores) ++ Bool.pick(String, U32.is_eq(cores, 1), " core", " cores") ++ " of this device"

def sc.best(+moves: String, +nodes: U32, +ms: Nat, +cores: U32) -> String:
  moves ++ "|" ++ U32.show(nodes) ++ "|" ++ Nat.show(ms) ++ "|ok|" ++ sc.where(cores) ++ "|"

def sc.rough(+w: String, +nodes: U32, +ms: Nat, +b: U32, +moves: String, +lim: Nat) -> String:
  w ++ "|" ++ U32.show(nodes) ++ "|" ++ Nat.show(ms) ++ "|ok|" ++ U32.show(b) ++ "|" ++ moves ++ "|" ++ Nat.show(lim) ++ "|"

def sc.late(+nodes: U32, +ms: Nat, +b: U32) -> String:
  "late|" ++ U32.show(nodes) ++ "|" ++ Nat.show(ms) ++ "|ok|" ++ U32.show(b) ++ "|"

# a bound's jobs: one, or one a prefix
def sc.jobs(+b: U32) -> String:
  Bool.pick(String, U32.is_lt(b, sc.split()), "job bound " ++ U32.show(b), "job subs " ++ U32.show(b))

def sc.count(+b: U32, +np: U32) -> U32:
  Bool.pick(U32, U32.is_lt(b, sc.split()), 1, np)

# The end: the answer said and kept (asked again, it is said again at once)
def sc.final(+s: Sc, +text: String) -> Sc & String:
  match s:
    case Sc{+key, run, b, short, cap, left, nodes, t0, said, +cores, last, np, lim}:
      (Sc{key, False{}, b, short, cap, 0, nodes, t0, said, cores, text, np, lim}, "say " ++ text ++ "\nend\nstop")

# the short way is a shortest one: every bound below its length searched
def sc.proven(+s: Sc, +now: Nat) -> Sc & String:
  match s:
    case Sc{key, run, b, +short, cap, left, +nodes, +t0, said, +cores, last, np, lim}:
      sc.final(s, sc.best(short, nodes, Nat.sub(now, t0), cores))

# bound b next: proven if the short way is no longer; else its jobs; past 20
# with no way known (it cannot be: every cube is 20 moves at most), the end
def sc.bound(+s: Sc, +b: U32, +now: Nat) -> Sc & String:
  match s:
    case Sc{+key, run, ob, +short, +cap, left, +nodes, +t0, +said, +cores, +last, +np, lim}:
      Bool.pick(Sc & String, U32.is_ge(b, cap), sc.proven(s, now),
      Bool.pick(Sc & String, U32.is_gt(b, 20), sc.final(s, sc.late(nodes, Nat.sub(now, t0), b)),
        (Sc{key, True{}, b, short, cap, sc.count(b, np), nodes, t0, said, cores, last, np, lim}, sc.jobs(b))))

# Events
# ------

# a new cube: the jobs for its short way (three axes) and its bound
def sc.start.new(+s: Sc, +key: String, +now: Nat, +cores: U32, +np: U32, +l: Nat) -> Sc & String:
  (Sc{key, True{}, 0, "", 99, 0, 0, now, now, cores, "", np, l}, "stop\njob two 0\njob two 1\njob two 2\njob h")

def sc.start.go(same: Bool, +s: Sc, +key: String, +now: Nat, +cores: U32, +np: U32, +l: Nat) -> Sc & String:
  match same s:
    case True{} Sc{+k, +run, +b, +short, +cap, +left, +nodes, +t0, +said, +cores2, +last, +np2, lim}:
      # the same cube again, with time limit l: while it runs, l from now
      # on, and how it goes; stopped at its limit (its last answer "short" or
      # "late") and asked with none, it goes on from the bound it stopped in
      # (the time it sat stopped not counted); else its last answer again
      +cut = Bool.or(String.starts_with(last, "short|"), String.starts_with(last, "late|"))
      +s2 : Sc = Sc{k, run, b, short, cap, left, nodes, t0, said, cores2, last, np2, l}
      Bool.pick(Sc & String, run,
        (s2, Bool.pick(String, String.is_empty(short), "", "say " ++ sc.rough("working", nodes, Nat.sub(now, t0), b, short, l))),
        Bool.pick(Sc & String, Bool.and(cut, Nat.is_eq(l, 0n)),
          sc.bound(Sc{k, True{}, b, short, cap, 0, nodes, Nat.add(t0, Nat.sub(now, said)), now, cores2, "", np2, l}, b, now),
          (s, "say " ++ last ++ "\nend")))
    case False{} _:
      sc.start.new(s, key, now, cores, np, l)

# a start's LIMIT (none said: sc.limit())
def sc.lim.of(+w: String) -> Nat:
  Bool.pick(Nat, String.is_empty(w), sc.limit(), sc.nat(w))

def sc.start(+s: Sc, +ws: List<&2, String>) -> Sc & String:
  match s:
    case Sc{+key, run, b, short, cap, left, nodes, t0, said, cores, last, np, lim}:
      +k = sc.word(ws, 4n)
      sc.start.go(Bool.and(String.eq(k, key), Bool.not(String.is_empty(key))), s, k, sc.nat(sc.word(ws, 1n)), sc.num(sc.word(ws, 2n)), sc.num(sc.word(ws, 3n)), sc.lim.of(sc.word(ws, 5n)))

# the cube's bound: 0 (it is solved), or the bound loop from there
def sc.h(+s: Sc, +ws: List<&2, String>) -> Sc & String:
  match s:
    case Sc{key, +run, b, short, cap, left, nodes, +t0, said, +cores, last, np, lim}:
      +now = sc.nat(sc.word(ws, 1n))
      +h = sc.num(sc.word(ws, 2n))
      Bool.pick(Sc & String, Bool.not(run), (s, ""),
        Bool.pick(Sc & String, U32.is_zero(h), sc.final(s, sc.best("", 0, Nat.sub(now, t0), cores)), sc.bound(s, h, now)))

# a short way: kept if shorter; if no longer than the bound being searched
# (every bound below it searched), it is a shortest one
def sc.two.keep(+s: Sc, +moves: String, +n: U32, +now: Nat) -> Sc & String:
  match s:
    case Sc{+key, +run, +b, short, cap, +left, +nodes, +t0, said, +cores, +last, np, +lim}:
      +s2 : Sc = Sc{key, run, b, moves, n, left, nodes, t0, now, cores, last, np, lim}
      Bool.pick(Sc & String, Bool.and(U32.is_gt(b, 0), U32.is_le(n, b)), sc.proven(s2, now),
        (s2, "say " ++ sc.rough("working", nodes, Nat.sub(now, t0), b, moves, lim)))

def sc.two(+s: Sc, +ws: List<&2, String>) -> Sc & String:
  match s:
    case Sc{key, +run, b, short, +cap, left, nodes, t0, said, cores, last, np, lim}:
      +n = sc.num(sc.word(ws, 4n))
      Bool.pick(Sc & String, Bool.and(Bool.and(run, String.eq(sc.word(ws, 2n), "ok")), U32.is_lt(n, cap)),
        sc.two.keep(s, sc.word(ws, 3n), n, sc.nat(sc.word(ws, 1n))), (s, ""))

# a job of bound b done: a solution (a shortest one), or one fewer to go
def sc.res.none(+s: Sc, +nodes2: U32, +now: Nat) -> Sc & String:
  match s:
    case Sc{+key, +run, +b, +short, +cap, +left, nodes, +t0, +said, +cores, +last, np, lim}:
      +l = U32.sub(left, 1)
      +s2 : Sc = Sc{key, run, b, short, cap, l, nodes2, t0, said, cores, last, np, lim}
      Bool.pick(Sc & String, U32.is_zero(l), sc.bound(s2, U32.add(b, 1), now), (s2, ""))

def sc.res(+s: Sc, +ws: List<&2, String>) -> Sc & String:
  match s:
    case Sc{key, +run, +b, short, cap, left, +nodes, +t0, said, +cores, last, np, lim}:
      +now = sc.nat(sc.word(ws, 1n))
      +n = U32.add(nodes, sc.num(sc.word(ws, 5n)))
      Bool.pick(Sc & String, Bool.or(Bool.not(run), U32.is_ne(sc.num(sc.word(ws, 2n)), b)), (s, ""),
        Bool.pick(Sc & String, String.eq(sc.word(ws, 3n), "ok"), sc.final(s, sc.best(sc.word(ws, 4n), n, Nat.sub(now, t0), cores)),
          sc.res.none(s, n, now)))

# the clock: past the limit, the short way (not proven); every 2 s, how it goes
def sc.tick(+s: Sc, +ws: List<&2, String>) -> Sc & String:
  match s:
    case Sc{+key, +run, +b, +short, +cap, +left, +nodes, +t0, +said, +cores, +last, np, +lim}:
      +now = sc.nat(sc.word(ws, 1n))
      +ms = Nat.sub(now, t0)
      Bool.pick(Sc & String, Bool.not(run), (s, ""),
        Bool.pick(Sc & String, Bool.and(Nat.is_gt(lim, 0n), Nat.is_ge(ms, lim)),
          sc.final(s, Bool.pick(String, String.is_empty(short), sc.late(nodes, ms, b), sc.rough("short", nodes, ms, b, short, lim))),
          Bool.pick(Sc & String, Bool.and(Nat.is_ge(Nat.sub(now, said), 2000n), Bool.not(String.is_empty(short))),
            (Sc{key, run, b, short, cap, left, nodes, t0, now, cores, last, np, lim}, "say " ++ sc.rough("working", nodes, ms, b, short, lim)),
            (s, ""))))

def sc.on.go(+s: Sc, +ws: List<&2, String>, +e: String) -> Sc & String:
  Bool.pick(Sc & String, String.eq(e, "start"), sc.start(s, ws),
  Bool.pick(Sc & String, String.eq(e, "h"), sc.h(s, ws),
  Bool.pick(Sc & String, String.eq(e, "two"), sc.two(s, ws),
  Bool.pick(Sc & String, String.eq(e, "res"), sc.res(s, ws),
  Bool.pick(Sc & String, String.eq(e, "tick"), sc.tick(s, ws), (s, ""))))))

# an event: the next state, and the commands (lines)
def sc.on(s: Sc, ev: String) -> Sc & String:
  +ws = String.split(ev, ' ')
  sc.on.go(s, ws, sc.word(ws, 0n))
