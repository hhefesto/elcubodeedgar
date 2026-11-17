# El cubo de Edgar

Edgar's Rubik's cube, https://elcubodeedgar.hhefesto.dev: scramble a cube in
3D, or turn its faces yourself, and step through its optimal solution, one
animated turn at a time.

The site is static files (xty serves them); the visitor's own device does the
solving, in Bend compiled to JavaScript, on a Web Worker for each of its
cores. Everything that thinks is Bend, and what it stands on is proved in
Bend (see "What is proved", below):

- `Cube.bend`: the cube as a group element (Kociemba's cubie level), its moves,
  notation and stickers.
- `Guard.bend`: a cube from its 54 stickers' colors, or plainly why a real
  cube cannot have them (counts, centers, pieces, each piece once, corner
  twist, edge flip, permutation parity). Every cube the device solves goes
  through it; LAWS.bend's read_* and refuse_* laws.

On the visitor's device:

- `Dev.bend`: what a Web Worker runs. The corners' move tables (made on the
  device), the shortest search (Kd.bend), one bound at a time, or one subtree
  of a bound (a three-move prefix of the 3,240) at a time: independent
  calls, so a bound spreads over every worker; Lite.bend's two-phase answer
  for one of the cube's three axes; and the "Enter your own cube" panel's
  Bend (dv.check, dv.photo, dv.undo). Every answer is checked by Cube.bend.
- `Kd.bend`: the shortest search's bound, Kociemba's optimal solver's table
  made small enough for a browser: each cube's exact distance to the
  subgroup where edges are unflipped, corners untwisted and the U-D slice
  edges in their slice, by flip, slice places and twist (2.2 billion cubes),
  kept by class under the 8 turns that keep the U-D axis (127,166 classes x
  2,187 twists) at 2 bits an entry (the distance mod 3: the search knows its
  node's exact distance and a move changes it by at most one). Looked up on
  the cube's three axes (the cube turned by URF3, URF3^2), with the corners'
  exact distances: the bound is the largest of the four, about one move more
  than Korf's corners and two sets of six edges gave, and each move is ~13x
  the nodes. Made by `FstTables.bend` (30 s on 8 cores).
- `Lite.bend`: Kociemba's two-phase algorithm with tables a phone can hold
  (phase 1 bounded by two exact distances of parts, 2048 x 495 and
  2187 x 495; phase 2 as TwoPhase.bend's): a short way back, about 20 moves,
  in a second or two.
- `DevTables.bend`, `FstTables.bend`: the tables the device downloads, made
  once (`nix build .#dev-tables`): the corners' 44 MB, Kd.bend's 80 MB and
  Lite's 18 MB, kept as brotli (6.2, 42.8 and 1.5 MB) and gzip, named by
  their contents, so a browser keeps them for good (Cache API).
- `web/Sched.bend`: what the workers do for a cube and what the page is told:
  two-phase on three axes first (a short way at once; the position's own
  moves undone, from the page, are one too, so no answer is longer than
  them), then the shortest search's bounds,
  from 11 on split into the 3,240 subtrees for any free worker; a solution is
  called shortest only when every shorter bound was searched in full (or once
  the bounds reach the short way's length). Past 240 s the page gets the
  short way, marked as not proven the shortest, with what was ruled out;
  unless the visitor turns on "No time limit" (kept on the device), and then
  it searches on until it proves the shortest (a search that stopped at the
  limit goes on from the bound it stopped in). Why 240 s: each move more
  multiplies the sequences to rule out by about 13, so a 17-move cube is
  often proven within a minute, while an 18 (two cubes in three) needs every
  17 ruled out first, about 13 times that.
- `web/solver.js`, `web/solver-worker.js`: the thin JS around it: the
  workers, the tables in one SharedArrayBuffer they all read (so the page
  must be cross-origin isolated: xty sends COOP and COEP), jobs to free
  workers. A browser that cannot gets a quick way instead: Lite.bend's
  two-phase alone, on one worker (or on the page), marked "quick", not proven
  the shortest. Nothing is ever asked of a server: the site only serves files.
- `web/App.bend`: the page, a bend-frp app; it holds the cube and tells the 3D
  view (`web/cube3d.js`, three.js) which turn to animate and what the stickers
  are after it. Random scrambles (25 moves), turns by hand (the 18
  buttons, or the keys u r f d l b, shift for back), Solve, Next step, Play,
  "What do these buttons mean?" (the moves explained, `web/index.html`), and,
  when a device cannot prove the shortest in time, a link (`/#m=3.10.17`, the
  position in the fragment, never sent to a server) to open the same cube on
  a bigger one. "Enter your own cube" (`web/own.js`, a thin shim): paint the
  stickers on a flat net, or read them with the camera a face at a time
  (Photo.bend gives each sticker the color of the center it looks most
  like) and fix them by painting; Guard.bend says plainly why the stickers
  cannot be a real cube, if they cannot; the cube is then shown as a
  `#m=` position (a short solution, undone) and solved as any other. The 3D
  view turns freely (a quaternion trackball: drag any way, any face to the
  front; a double tap brings it back).
- "Solve it your way" (`Ways.bend`, in a worker of its own:
  `web/ways-worker.js`): beside the fewest moves, the ways people solve a
  cube, for the same position, each card with its moves and how many times
  the fewest they are; the one picked (or the keys 1 to 4) is what the
  strip shows, step by step, and what Next step and Play make. F2L (CFOP):
  the cross on the bottom and each F2L pair in the fewest moves (IDA* over
  the pieces it follows, bounded by breadth-first tables of three pieces),
  then one of J Perm's 57 OLL and one of his 21 PLL algorithms; F2L,
  simplified: the same, then the top in four looks (2-look OLL and PLL, 16
  algorithms); the beginner's: layer by layer, as Rubik's own guide
  teaches. An algorithm is tried from each side (a turn of the whole cube
  costs no move); its notation (wide turns, slices, rotations) is read into
  the face turns of a cube whose centers stay put. Each way's moves are
  checked by Cube.bend, there and again on the page. The tables take about
  0.3 s, a position about 0.1 s (JavaScript, a laptop); `probe/WaysT.bend`
  solves 200 random scrambles each way (600 of 600; CFOP 52.3 moves on
  average, four-look 66.0, beginner's 134.1), `probe/ways.sh` drives the
  page, and `ALGS.bend` has the algorithms' laws (each keeps what its step
  keeps; Bend's checker, as BendTT's kernel runs out of fuel on them).

Not used by the site (it asks no server; the user, 11-16: "I don't want
Edgar's site to use delfos at all"): the first, server-side solver, kept as
code:

- `Coord.bend`, `Sym.bend`, `Kc.bend`, `Build.bend`: the big tables. The
  corners' exact distances, and, as in Kociemba's optimal solver, the exact
  distances of the edges' flips, the four U-D slice edges' places and the
  corners' twists, kept by class under the eight turns of the whole cube that
  keep the U-D axis (3,044,504 classes, 6.66 billion positions, 3.6 GB).
- `Opt.bend`, `Fast.bend`, `TwoPhase.bend`, `Worker.bend`, `Server.bend`: IDA*
  over them on 8 cores, two-phase first, the solver as a process of its own
  (127.0.0.1:8095, joins a re-asked cube's search, 120 s a cube), and the
  server (127.0.0.1:8093) that hands it the asks.
- `Group.bend`, `LAWS.bend`, `PROOF.bend`: the group theory the solvers stand
  on, and the guard's laws, as laws, each proven (`bend PROOF.bend --verdict`).
- `Solve.bend`, `Par.bend`: the first solver, whose table code the others
  build on.

```
nix build .#www           # the site: the page, dev.mjs, the workers' JS, t/ (the tables), tables.json
nix build                 # delfos's page server: result/bin/elcubodeedgar [PORT]
nix build .#solver        # delfos's solver and its tables: elcubodeedgar-solver [PORT]
nix flake check           # the proofs (and BendTT's verdict), the camera's and the ways' laws, every module, the 3D turns
```

It used to run on delfos as systemd user units (copies in `deploy/`); they
are stopped and disabled, and xty has no `/api/` any more.

`probe/site-test.sh WWW PORT` serves the site as xty does (nginx, the same
headers); `probe/bench.html` and `probe/bench.sh` time the device's solver in
headless Chrome with 1, 2, 4, 8 workers, each answer checked by
`probe/Check.bend`; `probe/shot.mjs` takes screenshots (`DPR=3 node
probe/shot.mjs URL 390x844 ...` for a phone); `probe/turns.mjs` checks that the
3D view's turns move the stickers as `Cube.bend` does; `probe/solve-tests.sh`
asks the old server-side solver (not used by the site).

A Bend program's `main` run as `bend File.bend` is interpreted, and slowly:
a test of `Ways.bend`'s tables ran 24 minutes that way, built (`bend
File.bend -o /tmp/x && /tmp/x`) 0.02 s. Probes that compute are built first.

## What is proved

A test checks examples; a proof covers every case, and a checker, a program
much smaller than the one it checks, goes through it. In Bend a claim is a
type (a `law`) and its proof a program of that type: `bend PROOF.bend`
accepts it only if the proof is right, and `bend PROOF.bend --verdict` has
BendTT's kernel check it again (the flake's check `proofs`). A cube is
finite, so most proofs here are by computation: a case for each face (and
turn) where both sides compute to the same cube, closed by `{==}`.

- `LAWS.bend` (66 laws, proofs in `PROOF.bend`, checker and kernel): the
  cube is a group (each face's turns a cyclic group of order 4, every move
  undone by its inverse, two turns of a face merge, opposite faces commute,
  others do not, `R U R' U'` six times and `R U` 105 times are no move, the
  superflip commutes with every move, every move keeps corner twist, edge
  flip and parity); the search skips only what may be skipped (the face it
  just turned, the face across in one order, any first move); Guard.bend
  reads back the solved cube, every move, the superflip and a 23-move
  scramble from their stickers, and refuses a twisted corner, a flipped
  edge, two swapped pieces and a wrong color count at every place; moves
  read back from links and notation; "Enter your own cube"'s way back
  solves its cube; Kd.bend's mod-3 distances and its 4,096 mask ranks;
  Photo.bend's photo lines, hold pictures and colors; Scheme.bend's presets.
- `ALGS.bend` (9 laws, the checker only: the kernel runs out of fuel): every
  OLL, PLL, four-look and beginner's algorithm of "Solve it your way" reads
  as written and keeps what its step must keep.
- `FIT.bend` (5 laws, the checker only, as above): the camera's color-scheme
  fit and its reading of a scrambled cube, and "Enter your own cube" on the
  23-move scramble.

Not proved: that IDA* finds a shortest solution for every cube (sound when
its tables never overestimate a cube's distance, which is not proved here),
and the JavaScript around the Bend. So the page checks every answer as it
comes, playing its moves on the cube with `Cube.bend`, and shows only one
that solves it. The page's "Proved, not just tested" says the same for
visitors.
