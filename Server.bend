import Base
import ./Cube.bend as C
import ./Par.bend as P
import ./Solve.bend as V

# The cube's web server: the page's files, and the solver.
#
#   cube-server <www> <port>
#
# builds the tables (about a minute), then answers on 127.0.0.1:<port>, one
# request at a time, each connection closed after its answer:
#   GET /api/solve?m=3.10.17   a shortest solution of the cube those moves
#                              make from solved (moves numbered as Cube.bend's)
#   GET /<name>                the file <www>/<name> (/ is index.html)
#
# The solve's answer is four lines: the moves ("" for none, "none" if no
# solution within 20), the nodes searched, the milliseconds, and "ok" when
# the scramble then the solution leaves the cube solved (checked here, by
# Cube.bend, on every answer).
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
  hs.type.pick(String.ends_with(name, ".html"), String.ends_with(name, ".js"), String.ends_with(name, ".css"),
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

# The solver
# ----------

def hs.api.say(s: Socket, +ms: List<&2, U32>, ans: V.Ans, +ms_taken: Nat) -> IO(Unit):
  match ans:
    case V.Ans{Some{+sol}, k, b}:
      +ok = C.cube.is_solved(C.cube.apply(sol, C.cube.apply(ms, C.cube.solved())))
      +body = C.cube.nums(sol) ++ "\n" ++ U32.show(k) ++ "\n" ++ Nat.show(ms_taken) ++ "\n" ++ Bool.pick(String, ok, "ok", "WRONG") ++ "\n"
      do IO<Unit>:
        IO.print("solve " ++ C.cube.show(ms) ++ " -> " ++ C.cube.show(sol) ++ " (" ++ U32.show(hs.count(sol)) ++ " moves, " ++ U32.show(k) ++ " nodes, " ++ Nat.show(ms_taken) ++ " ms)")
        hs.text(s, "200 OK", body)
    case V.Ans{None{}, k, b}:
      do IO<Unit>:
        IO.print("solve " ++ C.cube.show(ms) ++ " -> none within 20")
        hs.text(s, "200 OK", "none\n" ++ U32.show(k) ++ "\n" ++ Nat.show(ms_taken) ++ "\nok\n")

def hs.api.timed(s: Socket, r: P.Ts & V.Ans, +ms: List<&2, U32>, +t0: Nat) -> IO(P.Ts):
  (ts, ans) = r
  match ans:
    case V.Ans{f, +k, +b}:
      do IO<P.Ts>:
        t1 : Nat <- IO.now()
        hs.api.say(s, ms, V.Ans{f, k, b}, Nat.sub(t1, t0))
        return ts

# at most 14 moves in a scramble: its solution is then at most 14, which the
# search finds in seconds (15 can take minutes; a public server must not be held)
def hs.api.go(short: Bool, s: Socket, ts: P.Ts, +ms: List<&2, U32>) -> IO(P.Ts):
  match short:
    case True{}:
      do IO<P.Ts>:
        t0 : Nat <- IO.now()
        hs.api.timed(s, V.sv.solve(ts, ms), ms, t0)
    case False{}:
      do IO<P.Ts>:
        hs.text(s, "400 Bad Request", "at most 14 moves\n")
        return ts

def hs.api(s: Socket, ts: P.Ts, m: Maybe<&2, List<&2, U32>>) -> IO(P.Ts):
  match m:
    case Some{+ms}:
      hs.api.go(U32.is_le(hs.count(ms), 14), s, ts, ms)
    case None{}:
      do IO<P.Ts>:
        hs.text(s, "400 Bad Request", "m: moves 0..17 joined by '.'\n")
        return ts

def hs.route.go(api: Bool, s: Socket, ts: P.Ts, +www: String, +path: String) -> IO(P.Ts):
  match api:
    case True{}:
      hs.api(s, ts, C.cube.read(String.drop(path, 13n)))
    case False{}:
      do IO<P.Ts>:
        hs.file(s, www, hs.before(path))
        return ts

def hs.route(s: Socket, ts: P.Ts, +www: String, +path: String) -> IO(P.Ts):
  hs.route.go(String.starts_with(path, "/api/solve?m="), s, ts, www, path)

# Connections
# -----------

def hs.answer(rd: Socket & Poll<&1, &1, Result<&1, &1, U32 & String, Maybe<&1, String>>, Unit>, ts: P.Ts, +www: String) -> IO(P.Ts):
  (s, p) = rd
  match p:
    case Ready{Done{Some{req}}}:
      hs.route(s, ts, www, hs.target(req))
    case _:
      do IO<P.Ts>:
        Socket.close(s)
        return ts

def hs.conn(m: Listener & Result<&1, &1, U32 & String, Socket>, ts: P.Ts, +www: String) -> IO(Listener & P.Ts):
  (l, res) = m
  match res:
    case Done{s}:
      do IO<Listener & P.Ts>:
        rd : Socket & Poll<&1, &1, Result<&1, &1, U32 & String, Maybe<&1, String>>, Unit> <- TCP.try_recv(s, 16384, 5000)
        ts2 : P.Ts <- hs.answer(rd, ts, www)
        return (l, ts2)
    case Fail{e}:
      IO.pure(Listener & P.Ts, (l, ts))

# one connection after another, until killed
@unsafe
def hs.serve(r: Listener & P.Ts, +www: String) -> IO(Unit):
  (l, ts) = r
  do IO<Unit>:
    m : Listener & Result<&1, &1, U32 & String, Socket> <- TCP.accept(l)
    r2 : Listener & P.Ts <- hs.conn(m, ts, www)
    hs.serve(r2, www)

def hs.args(xs: List<String>) -> String & String:
  match xs:
    case Con{a, Con{b, Con{c, t}}}:
      (b, c)
    case _:
      ("www", "8093")

def hs.start(+www: String, +port: U32, ts: P.Ts, +t0: Nat) -> IO(Unit):
  do IO<Unit>:
    +t1 : Nat <- IO.now()
    IO.print("tables built in " ++ Nat.show(Nat.sub(t1, t0)) ++ " ms")
    l : Listener <- IO.try(Listener, TCP.listen("127.0.0.1", port))
    IO.print("serving " ++ www ++ " on http://127.0.0.1:" ++ U32.show(port))
    hs.serve((l, ts), www)

def hs.main(p: String & String, ts: P.Ts, +t0: Nat) -> IO(Unit):
  (+www, +port) = p
  hs.start(www, Maybe.default(&2, U32, U32.read(port), 8093), ts, t0)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    t0 : Nat <- IO.now()
    hs.main(hs.args(args), V.sv.lanes(), t0)
