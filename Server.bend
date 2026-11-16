import Base
import ./Cube.bend as C

# The cube's web server: the page's files, and the way to the solver.
#
#   cube-server <www> <port>
#
# answers on 127.0.0.1:<port>, each connection in a computation of its own,
# closed after its answer:
#   GET /api/solve?m=3.10.17&v=V  a shortest solution of the cube those
#                              moves make from solved (moves numbered as
#                              Cube.bend's), for the page V
#   GET /health                "ok"
#   GET /<name>                the file <www>/<name> (/ is index.html)
#
# It solves nothing itself: the solver is a process of its own (Worker.bend,
# cube-solver, on 127.0.0.1:8095, elcubodeedgar-solver.service), so the page
# and its files answer at once whatever the solver is doing. A solve is
# handed to it with who asks (the page's own name for itself, else the
# visitor's address), so a page's new cube cancels its old one, and the same
# cube asked again joins its search. The solver answers within its own wait
# (wk.wait, 20 s: the answer, or "working" with how far it got, or
# "queued"; the page asks again); if it does not within hs.wait(), its event
# loop is stuck, and this server kills it (systemd starts it again) and says
# "down". While the solver is replaced, a standby on 127.0.0.1:8096 answers:
# a cube goes to the main one, else the standby, else the answer is "down"
# (and the page asks again in a few seconds). ELCUBO_SOLVER_PORT, if set, is
# the main one's port (a test's).
#
# The solve's answer is the solver's (Worker.bend), or "down" while no solver
# answers (one is starting: the page asks again).
#
# Every def is prefixed `hs.`.

# What a file is, by its name's end
def hs.type.pick(html: Bool, js: Bool, css: Bool, svg: Bool, woff: Bool, png: Bool) -> String:
  match html js css svg woff png:
    case True{} _ _ _ _ _:
      "text/html; charset=utf-8"
    case False{} True{} _ _ _ _:
      "text/javascript; charset=utf-8"
    case False{} False{} True{} _ _ _:
      "text/css; charset=utf-8"
    case False{} False{} False{} True{} _ _:
      "image/svg+xml"
    case False{} False{} False{} False{} True{} _:
      "font/woff2"
    case False{} False{} False{} False{} False{} True{}:
      "image/png"
    case False{} False{} False{} False{} False{} False{}:
      "application/octet-stream"

def hs.type(+name: String) -> String:
  hs.type.pick(String.ends_with(name, ".html"), Bool.or(String.ends_with(name, ".js"), String.ends_with(name, ".mjs")), String.ends_with(name, ".css"),
               String.ends_with(name, ".svg"), String.ends_with(name, ".woff2"), String.ends_with(name, ".png"))

def hs.head(+status: String, +ctype: String, +len: Nat, +cache: String) -> String:
  "HTTP/1.1 " ++ status ++ "\r\nContent-Type: " ++ ctype ++ "\r\nContent-Length: " ++ Nat.show(len)
    ++ "\r\nCache-Control: " ++ cache ++ "\r\nX-Content-Type-Options: nosniff\r\nConnection: close\r\n\r\n"

# Sending
# -------

def hs.sent(m: Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>) -> IO(Unit):
  (s, r) = m
  Socket.close(s)

# a text answer (ASCII: its length is its bytes'), then the connection closed
def hs.text(s: Socket, +status: String, +body: String) -> IO(Unit):
  do IO<Unit>:
    m : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send(s, hs.head(status, "text/plain; charset=utf-8", String.length(body), "no-store") ++ body)
    hs.sent(m)

def hs.body(m: Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>, +bs: List<&2, U32>) -> IO(Unit):
  (s, r) = m
  do IO<Unit>:
    m2 : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send_bytes(s, bs)
    hs.sent(m2)

# Files
# -----

def hs.file.got(s: Socket, +name: String, m: File & Result<&1, &1, U32 & String, List<&2, U32>>) -> IO(Unit):
  (f, r) = m
  match r:
    case Done{+bs}:
      do IO<Unit>:
        File.close(f)
        m1 : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send(s, hs.head("200 OK", hs.type(name), List.length(&2, U32, bs), "public, max-age=300"))
        hs.body(m1, bs)
    case Fail{e}:
      do IO<Unit>:
        File.close(f)
        hs.text(s, "500 Internal Server Error", "could not read it\n")

def hs.file.opened(s: Socket, +name: String, r: Result<&1, &1, U32 & String, File>) -> IO(Unit):
  match r:
    case Done{f}:
      do IO<Unit>:
        m : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(f, 33554432)
        hs.file.got(s, name, m)
    case Fail{e}:
      hs.text(s, "404 Not Found", "not found\n")

# A name the server gives out: letters, digits, '.', '-', '_', not starting
# with '.' (so no "..", no '/', no hidden file)
def hs.safe.c(+c: Char) -> Bool:
  Bool.or(Bool.or(Char.is_alpha(c), Char.is_digit(c)), Bool.or(Bool.or(Char.is_eq(c, '.'), Char.is_eq(c, '-')), Char.is_eq(c, '_')))

def hs.safe.go(s: String) -> Bool:
  match s:
    case SNil{}:
      True{}
    case SCon{+c, t}:
      Bool.and(hs.safe.c(c), hs.safe.go(t))

def hs.safe(s: String) -> Bool:
  match s:
    case SNil{}:
      False{}
    case SCon{+c, t}:
      Bool.and(Bool.not(Char.is_eq(c, '.')), hs.safe.go(SCon{c, t}))

def hs.file.if(ok: Bool, s: Socket, +www: String, +name: String) -> IO(Unit):
  match ok:
    case True{}:
      do IO<Unit>:
        r : Result<&1, &1, U32 & String, File> <- File.open(www ++ "/" ++ name, "r")
        hs.file.opened(s, name, r)
    case False{}:
      hs.text(s, "404 Not Found", "not found\n")

# The file a path names: "/" is index.html; "/a.js" is a.js
def hs.name(+path: String) -> String:
  Bool.pick(String, String.eq(path, "/"), "index.html", String.drop(path, 1n))

def hs.file(s: Socket, +www: String, +path: String) -> IO(Unit):
  +name = hs.name(path)
  hs.file.if(hs.safe(name), s, www, name)

# The request
# -----------

# what comes before the first '?'
def hs.before(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{+c, t}:
      Bool.pick(String, Char.is_eq(c, '?'), SNil{}, SCon{c, hs.before(t)})

# the request's target: the second word of its first line
def hs.target(req: String) -> String:
  +line = Maybe.default(&2, String, List.get(&2, String, String.split(req, '\n'), 0n), "")
  Maybe.default(&2, String, List.get(&2, String, String.split(line, ' '), 1n), "/")

def hs.count(ms: List<&2, U32>) -> U32:
  match ms:
    case Nil{}:
      0
    case Con{m, t}:
      U32.add(hs.count(t), 1)


# The way to the solver
# ---------------------

# how long the solver may take to answer an ask before it counts as stuck:
# it answers within 20 s (wk.wait: the answer, "working" or "queued"), its
# steps take a few seconds at most; Safari gives up on a request at 60 s
def hs.wait() -> U32:
  45000

def hs.solver.port() -> U32:
  8095

# the longest scramble taken (a cube is at most 20 moves from solved; a
# scramble, or a hand's turns, may be longer)
def hs.most() -> U32:
  400

# the lines after the headers' blank one
def hs.after.blank(ls: List<&2, String>) -> List<&2, String>:
  match ls:
    case Nil{}:
      Nil{}
    case Con{+l, +rest}:
      Bool.pick(List<&2, String>, Bool.or(String.is_empty(l), String.eq(l, "\r")), rest, hs.after.blank(rest))

def hs.body.of(+r: String) -> String:
  String.join(hs.after.blank(String.split(r, '\n')), "\n")

# the solver's answer read to its end (k reads at most)
def hs.got(k: Nat, rd: Socket & Poll<&1, &1, Result<&1, &1, U32 & String, Maybe<&1, String>>, Unit>, +acc: String) -> IO(String):
  match k:
    case 0n:
      (sock, p) = rd
      do IO<String>:
        Socket.close(sock)
        return hs.body.of(acc)
    case 1n+q:
      (sock, p) = rd
      match p:
        case Ready{Done{Some{+part}}}:
          do IO<String>:
            rd2 : Socket & Poll<&1, &1, Result<&1, &1, U32 & String, Maybe<&1, String>>, Unit> <- TCP.try_recv(sock, 16384, hs.wait())
            hs.got(q, rd2, acc ++ part)
        case _:
          do IO<String>:
            Socket.close(sock)
            return hs.body.of(acc)

def hs.down() -> String:
  "down\n0\n0\nok\n0\n"

# whether a solver's answer is whole, and not "down" (cut short, or the
# solver going away, or still reading its tables)
def hs.line(+ls: List<&2, String>, +i: Nat) -> String:
  Maybe.default(&2, String, List.get(&2, String, ls, i), "")

def hs.whole(+b: String) -> Bool:
  +ls = String.split(b, '\n')
  Bool.and(String.eq(hs.line(ls, 3n), "ok"), Bool.not(String.eq(hs.line(ls, 0n), "down")))

def hs.request(+q: String) -> String:
  "GET /solve?" ++ q ++ " HTTP/1.0\r\nHost: solver\r\n\r\n"

def hs.read(m: Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>) -> IO(String):
  (sock, r) = m
  do IO<String>:
    rd : Socket & Poll<&1, &1, Result<&1, &1, U32 & String, Maybe<&1, String>>, Unit> <- TCP.try_recv(sock, 16384, hs.wait())
    hs.got(16n, rd, "")

# The standby solver (127.0.0.1:8096, only while the main one is replaced)
def hs.b.conn(c: Result<&1, &1, U32 & String, Socket>, +q: String) -> IO(String):
  match c:
    case Done{sock}:
      do IO<String>:
        m : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send(sock, hs.request(q))
        hs.read(m)
    case Fail{e}:
      IO.pure(String, hs.down())

def hs.b.ask(+p: U32, +q: String) -> IO(String):
  do IO<String>:
    c : Result<&1, &1, U32 & String, Socket> <- TCP.connect("127.0.0.1", U32.add(p, 1))
    hs.b.conn(c, q)

# The main solver (127.0.0.1:p, 8095); if it is not there, or does not answer
# whole, the standby (p + 1)
def hs.a.check.go(whole: Bool, +b: String, +p: U32, +q: String) -> IO(String):
  match whole:
    case True{}:
      IO.pure(String, b)
    case False{}:
      hs.b.ask(p, q)

def hs.a.check(+b: String, +p: U32, +q: String) -> IO(String):
  hs.a.check.go(hs.whole(b), b, p, q)

def hs.a.conn(c: Result<&1, &1, U32 & String, Socket>, +p: U32, +q: String) -> IO(String):
  match c:
    case Done{sock}:
      do IO<String>:
        m : Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit> <- TCP.send(sock, hs.request(q))
        +b : String <- hs.read(m)
        hs.a.check(b, p, q)
    case Fail{e}:
      hs.b.ask(p, q)

# the solver's port: ELCUBO_SOLVER_PORT (a test's), else hs.solver.port()
def hs.port.of(r: Result<&1, &1, U32 & String, String>) -> U32:
  match r:
    case Done{+s}:
      Maybe.default(&2, U32, U32.read(s), hs.solver.port())
    case Fail{e}:
      hs.solver.port()

def hs.ask.at(+p: U32, +q: String) -> IO(String):
  do IO<String>:
    c : Result<&1, &1, U32 & String, Socket> <- TCP.connect("127.0.0.1", p)
    hs.a.conn(c, p, q)

# the solver's answer to the query q ("v=..&m=.."): the main one's, or the
# standby's, or "down" if neither is there
def hs.ask(+q: String) -> IO(String):
  do IO<String>:
    e : Result<&1, &1, U32 & String, String> <- IO.get_env("ELCUBO_SOLVER_PORT")
    hs.ask.at(hs.port.of(e), q)

def hs.kill.done(r: Result<&1, &1, U32 & String, U32 & (String & String)>) -> IO(Unit):
  IO.pure(Unit, Unit{})

# the solver did not answer in time: its event loop is stuck; kill it
def hs.kill() -> IO(Unit):
  do IO<Unit>:
    IO.print("the solver did not answer in time: restarting it")
    r : Result<&1, &1, U32 & String, U32 & (String & String)> <- Process.run("/run/current-system/sw/bin/systemctl", ["--user", "restart", "elcubodeedgar-solver.service"], "", 4096, 20000)
    hs.kill.done(r)

def hs.relay(s: Socket, m: Maybe<&1, String>) -> IO(Unit):
  match m:
    case Some{+body}:
      hs.text(s, "200 OK", body)
    case None{}:
      do IO<Unit>:
        hs.text(s, "200 OK", hs.down())
        hs.kill()

# a header's value ("" if none), its name in lower case
def hs.header(ls: List<&2, String>, +k: String) -> String:
  match ls:
    case Nil{}:
      ""
    case Con{+l, +rest}:
      Bool.pick(String, String.starts_with(String.to_lower(l), k ++ ":"),
        String.trim(String.drop(l, Nat.add(String.length(k), 1n))), hs.header(rest, k))

# a name as the solver gets it: letters, digits, '.', ':' and '-' only (so
# nothing can be slipped into its request), at most 64
def hs.clean.c(+c: Char) -> Bool:
  Bool.or(Bool.or(Char.is_alpha(c), Char.is_digit(c)), Bool.or(Bool.or(Char.is_eq(c, '.'), Char.is_eq(c, ':')), Char.is_eq(c, '-')))

def hs.clean.go(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{+c, +t}:
      Bool.pick(String, hs.clean.c(c), SCon{c, hs.clean.go(t)}, hs.clean.go(t))

def hs.clean(+s: String) -> String:
  String.take(hs.clean.go(s), 64n)

# "k=V&..": the value of key k ("" if none)
def hs.param.go(ps: List<&2, String>, +k: String) -> String:
  match ps:
    case Nil{}:
      ""
    case Con{+p, rest}:
      Bool.pick(String, String.starts_with(p, k ++ "="), String.drop(p, Nat.add(String.length(k), 1n)), hs.param.go(rest, k))

def hs.param(+q: String, +k: String) -> String:
  hs.param.go(String.split(q, '&'), k)

# who asks: the page's own name for itself (its v=, one per page opened, so
# two people behind one address, or two tabs, do not cancel each other's
# cubes), else Cloudflare's word for the visitor's address
def hs.visitor(+req: String, +path: String) -> String:
  +v = hs.clean(hs.param(String.drop(path, 11n), "v"))
  Bool.pick(String, String.is_empty(v), "ip:" ++ hs.clean(hs.header(String.split(req, '\n'), "cf-connecting-ip")), "p:" ++ v)

# what comes before the first '&'
def hs.before.amp(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{+c, t}:
      Bool.pick(String, Char.is_eq(c, '&'), SNil{}, SCon{c, hs.before.amp(t)})

def hs.api.ok(ok: Bool, s: Socket, +vis: String, +ms: List<&2, U32>) -> IO(Unit):
  match ok:
    case True{}:
      do IO<Unit>:
        r : Maybe<&1, String> <- IO.within(String, hs.wait(), hs.ask("v=" ++ vis ++ "&m=" ++ C.cube.nums(ms)))
        hs.relay(s, r)
    case False{}:
      hs.text(s, "400 Bad Request", "at most " ++ U32.show(hs.most()) ++ " moves\n")

def hs.api.go(m: Maybe<&2, List<&2, U32>>, s: Socket, +vis: String) -> IO(Unit):
  match m:
    case Some{+ms}:
      hs.api.ok(U32.is_le(hs.count(ms), hs.most()), s, vis, ms)
    case None{}:
      hs.text(s, "400 Bad Request", "m: moves 0..17 joined by '.'\n")

def hs.api(s: Socket, +path: String, +vis: String) -> IO(Unit):
  hs.api.go(C.cube.read(hs.before.amp(String.drop(path, 13n))), s, vis)

def hs.route.go(api: Bool, health: Bool, s: Socket, +www: String, +path: String, +vis: String) -> IO(Unit):
  match api health:
    case True{} _:
      hs.api(s, path, vis)
    case False{} True{}:
      hs.text(s, "200 OK", "ok\n")
    case False{} False{}:
      hs.file(s, www, hs.before(path))

# Connections
# -----------

def hs.answer(rd: Socket & Poll<&1, &1, Result<&1, &1, U32 & String, Maybe<&1, String>>, Unit>, +www: String) -> IO(Unit):
  (s, p) = rd
  match p:
    case Ready{Done{Some{+req}}}:
      +path = hs.target(req)
      hs.route.go(String.starts_with(path, "/api/solve?m="), String.eq(path, "/health"), s, www, path, hs.visitor(req, path))
    case _:
      Socket.close(s)

def hs.handle(s: Socket, +www: String) -> IO(Unit):
  do IO<Unit>:
    rd : Socket & Poll<&1, &1, Result<&1, &1, U32 & String, Maybe<&1, String>>, Unit> <- TCP.try_recv(s, 16384, 5000)
    hs.answer(rd, www)

def hs.conn(m: Listener & Result<&1, &1, U32 & String, Socket>, +www: String) -> IO(Listener):
  (l, res) = m
  match res:
    case Done{s}:
      do IO<Listener>:
        IO.spawn(Unit, hs.handle(s, www))
        return l
    case Fail{e}:
      IO.pure(Listener, l)

# one connection after another, each in its own computation, until killed
@unsafe
def hs.serve(l: Listener, +www: String) -> IO(Unit):
  do IO<Unit>:
    m : Listener & Result<&1, &1, U32 & String, Socket> <- TCP.accept(l)
    l2 : Listener <- hs.conn(m, www)
    hs.serve(l2, www)

def hs.args(xs: List<String>) -> String & String:
  match xs:
    case Con{a, Con{b, Con{c, t}}}:
      (b, c)
    case _:
      ("www", "8093")

@unsafe
def hs.main(p: String & String) -> IO(Unit):
  (+www, +port) = p
  do IO<Unit>:
    l : Listener <- IO.try(Listener, TCP.listen("127.0.0.1", Maybe.default(&2, U32, U32.read(port), 8093)))
    IO.print("serving " ++ www ++ " on http://127.0.0.1:" ++ port ++ ", solving on 127.0.0.1:" ++ U32.show(hs.solver.port()))
    hs.serve(l, www)

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    hs.main(hs.args(args))
