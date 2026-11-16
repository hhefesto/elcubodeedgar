import Base

# What the device's workers do for a cube, and what the page is told: a
# state machine the page's thin JS (web/solver.js) feeds with what happens,
# and whose commands it carries out. The workers run Dev.bend.
#
#   events (words joined by spaces; a move list is "3.10.17", "" for none):
#     start NOW CORES NP FACELETS   a cube to solve (the same again: rejoin);
#                                   NP: how many prefixes a split bound has
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

# the time a cube gets, in ms
def sc.limit() -> Nat:
  120000n

# bounds from this one are split over the workers, a job a prefix
def sc.split() -> U32:
  11

# The state: the cube (its facelets), whether it runs, the bound being
# searched, the short way known (its moves, its length; 99 if none), the
# jobs of the bound not done, the nodes, when it began, when the page was
# last told, the cores, the last answer said and whose
type Sc is Data:
  Sc{+key: String, +run: Bool, +b: U32, +short: String, +cap: U32, +left: U32, +nodes: U32,
     +t0: Nat, +said: Nat, +cores: U32, +last: String, +np: U32}

def sc.init() -> Sc:
  Sc{"", False{}, 0, "", 99, 0, 0, 0n, 0n, 1, "", 0}

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

def sc.rough(+w: String, +nodes: U32, +ms: Nat, +b: U32, +moves: String) -> String:
  w ++ "|" ++ U32.show(nodes) ++ "|" ++ Nat.show(ms) ++ "|ok|" ++ U32.show(b) ++ "|" ++ moves ++ "|" ++ Nat.show(sc.limit()) ++ "|"

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
    case Sc{+key, run, b, short, cap, left, nodes, t0, said, +cores, last, np}:
      (Sc{key, False{}, b, short, cap, 0, nodes, t0, said, cores, text, np}, "say " ++ text ++ "\nend\nstop")

# the short way is a shortest one: every bound below its length searched
def sc.proven(+s: Sc, +now: Nat) -> Sc & String:
  match s:
    case Sc{key, run, b, +short, cap, left, +nodes, +t0, said, +cores, last, np}:
      sc.final(s, sc.best(short, nodes, Nat.sub(now, t0), cores))

# bound b next: proven if the short way is no longer; else its jobs; past 20
# with no way known (it cannot be: every cube is 20 moves at most), the end
def sc.bound(+s: Sc, +b: U32, +now: Nat) -> Sc & String:
  match s:
    case Sc{+key, run, ob, +short, +cap, left, +nodes, +t0, +said, +cores, +last, +np}:
      Bool.pick(Sc & String, U32.is_ge(b, cap), sc.proven(s, now),
      Bool.pick(Sc & String, U32.is_gt(b, 20), sc.final(s, sc.late(nodes, Nat.sub(now, t0), b)),
        (Sc{key, True{}, b, short, cap, sc.count(b, np), nodes, t0, said, cores, last, np}, sc.jobs(b))))

# Events
# ------

# a new cube: the jobs for its short way (three axes) and its bound
def sc.start.new(+s: Sc, +key: String, +now: Nat, +cores: U32, +np: U32) -> Sc & String:
  (Sc{key, True{}, 0, "", 99, 0, 0, now, now, cores, "", np}, "stop\njob two 0\njob two 1\njob two 2\njob h")

def sc.start.go(same: Bool, +s: Sc, +key: String, +now: Nat, +cores: U32, +np: U32) -> Sc & String:
  match same s:
    case True{} Sc{k, +run, b, +short, cap, left, +nodes, +t0, said, cores2, +last, np}:
      # the same cube again: its answer if there is one, else how it goes
      Bool.pick(Sc & String, run,
        (s, Bool.pick(String, String.is_empty(short), "", "say " ++ sc.rough("working", nodes, Nat.sub(now, t0), b, short))),
        (s, "say " ++ last ++ "\nend"))
    case False{} _:
      sc.start.new(s, key, now, cores, np)

def sc.start(+s: Sc, +ws: List<&2, String>) -> Sc & String:
  match s:
    case Sc{+key, run, b, short, cap, left, nodes, t0, said, cores, last, np}:
      +k = sc.word(ws, 4n)
      sc.start.go(Bool.and(String.eq(k, key), Bool.not(String.is_empty(key))), s, k, sc.nat(sc.word(ws, 1n)), sc.num(sc.word(ws, 2n)), sc.num(sc.word(ws, 3n)))

# the cube's bound: 0 (it is solved), or the bound loop from there
def sc.h(+s: Sc, +ws: List<&2, String>) -> Sc & String:
  match s:
    case Sc{key, +run, b, short, cap, left, nodes, +t0, said, +cores, last, np}:
      +now = sc.nat(sc.word(ws, 1n))
      +h = sc.num(sc.word(ws, 2n))
      Bool.pick(Sc & String, Bool.not(run), (s, ""),
        Bool.pick(Sc & String, U32.is_zero(h), sc.final(s, sc.best("", 0, Nat.sub(now, t0), cores)), sc.bound(s, h, now)))

# a short way: kept if shorter; if no longer than the bound being searched
# (every bound below it searched), it is a shortest one
def sc.two.keep(+s: Sc, +moves: String, +n: U32, +now: Nat) -> Sc & String:
  match s:
    case Sc{+key, +run, +b, short, cap, +left, +nodes, +t0, said, +cores, +last, np}:
      +s2 : Sc = Sc{key, run, b, moves, n, left, nodes, t0, now, cores, last, np}
      Bool.pick(Sc & String, Bool.and(U32.is_gt(b, 0), U32.is_le(n, b)), sc.proven(s2, now),
        (s2, "say " ++ sc.rough("working", nodes, Nat.sub(now, t0), b, moves)))

def sc.two(+s: Sc, +ws: List<&2, String>) -> Sc & String:
  match s:
    case Sc{key, +run, b, short, +cap, left, nodes, t0, said, cores, last, np}:
      +n = sc.num(sc.word(ws, 4n))
      Bool.pick(Sc & String, Bool.and(Bool.and(run, String.eq(sc.word(ws, 2n), "ok")), U32.is_lt(n, cap)),
        sc.two.keep(s, sc.word(ws, 3n), n, sc.nat(sc.word(ws, 1n))), (s, ""))

# a job of bound b done: a solution (a shortest one), or one fewer to go
def sc.res.none(+s: Sc, +nodes2: U32, +now: Nat) -> Sc & String:
  match s:
    case Sc{+key, +run, +b, +short, +cap, +left, nodes, +t0, +said, +cores, +last, np}:
      +l = U32.sub(left, 1)
      +s2 : Sc = Sc{key, run, b, short, cap, l, nodes2, t0, said, cores, last, np}
      Bool.pick(Sc & String, U32.is_zero(l), sc.bound(s2, U32.add(b, 1), now), (s2, ""))

def sc.res(+s: Sc, +ws: List<&2, String>) -> Sc & String:
  match s:
    case Sc{key, +run, +b, short, cap, left, +nodes, +t0, said, +cores, last, np}:
      +now = sc.nat(sc.word(ws, 1n))
      +n = U32.add(nodes, sc.num(sc.word(ws, 5n)))
      Bool.pick(Sc & String, Bool.or(Bool.not(run), U32.is_ne(sc.num(sc.word(ws, 2n)), b)), (s, ""),
        Bool.pick(Sc & String, String.eq(sc.word(ws, 3n), "ok"), sc.final(s, sc.best(sc.word(ws, 4n), n, Nat.sub(now, t0), cores)),
          sc.res.none(s, n, now)))

# the clock: past the limit, the short way (not proven); every 2 s, how it goes
def sc.tick(+s: Sc, +ws: List<&2, String>) -> Sc & String:
  match s:
    case Sc{+key, +run, +b, +short, +cap, +left, +nodes, +t0, +said, +cores, +last, np}:
      +now = sc.nat(sc.word(ws, 1n))
      +ms = Nat.sub(now, t0)
      Bool.pick(Sc & String, Bool.not(run), (s, ""),
        Bool.pick(Sc & String, Nat.is_ge(ms, sc.limit()),
          sc.final(s, Bool.pick(String, String.is_empty(short), sc.late(nodes, ms, b), sc.rough("short", nodes, ms, b, short))),
          Bool.pick(Sc & String, Bool.and(Nat.is_ge(Nat.sub(now, said), 2000n), Bool.not(String.is_empty(short))),
            (Sc{key, run, b, short, cap, left, nodes, t0, now, cores, last, np}, "say " ++ sc.rough("working", nodes, ms, b, short)),
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
