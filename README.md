# El cubo de Edgar

Edgar's Rubik's cube, https://elcubodeedgar.hhefesto.dev: scramble a cube in
3D, or turn its faces yourself, and step through its optimal solution, one
animated turn at a time.

The site is static files (xty serves them); the visitor's own device does the
solving, in Bend compiled to JavaScript, on a Web Worker for each of its
cores. Everything that thinks is Bend:

- `Cube.bend`: the cube as a group element (Kociemba's cubie level), its moves,
  notation and stickers.
- `Guard.bend`: a cube from its 54 stickers' colours, or plainly why a real
  cube cannot have them (counts, centres, pieces, each piece once, corner
  twist, edge flip, permutation parity). Every cube the device solves goes
  through it; LAWS.bend's read_* and refuse_* laws.

On the visitor's device:

- `Dev.bend`: what a Web Worker runs. Coord.bend's move tables (made on the
  device, the edges' rows split over the workers), Korf's IDA* (Search.bend)
  over Coord.bend's three distance tables (the corners; two sets of six
  edges), one bound at a time, or one subtree of a bound (a three-move prefix
  of the 3,240) at a time: independent calls, so a bound spreads over every
  worker; and Lite.bend's two-phase answer for one of the cube's three axes.
  Every answer is checked by Cube.bend.
- `Lite.bend`: Kociemba's two-phase algorithm with tables a phone can hold
  (phase 1 bounded by two exact distances of parts, 2048 x 495 and
  2187 x 495; phase 2 as TwoPhase.bend's): a short way back, about 20 moves,
  in a second or two.
- `DevTables.bend`: the tables the device downloads, made once (`nix build
  .#dev-tables`): Korf's 86.7 MB and Lite's 18 MB, kept as brotli (21.9 MB
  and 1.5 MB) and gzip (40.9 MB and 2.3 MB), named by their contents, so a
  browser keeps them for good (Cache API).
- `web/Sched.bend`: what the workers do for a cube and what the page is told:
  two-phase on three axes first (a short way at once), then Korf's bounds,
  from 11 on split into the 3,240 subtrees for any free worker; a solution is
  called shortest only when every shorter bound was searched in full (or once
  the bounds reach the short way's length). Past 120 s the page gets the
  short way, marked as not proven the shortest, with what was ruled out.
- `web/solver.js`, `web/solver-worker.js`: the thin JS around it: the
  workers, the tables in one SharedArrayBuffer they all read (so the page
  must be cross-origin isolated: xty sends COOP and COEP), jobs to free
  workers. A browser that cannot asks the site's own solver (`/api/solve`, on
  delfos, below), if it is there.
- `web/App.bend`: the page, a bend-frp app; it holds the cube and tells the 3D
  view (`web/cube3d.js`, three.js) which turn to animate and what the stickers
  are after it. Random scrambles (12 to 16 moves), turns by hand (the 18
  buttons, or the keys u r f d l b, shift for back), Solve, Next step, Play,
  "What do these buttons mean?" (the moves explained, `web/index.html`), and,
  when a device cannot prove the shortest in time, a link (`/#m=3.10.17`, the
  position in the fragment, never sent to a server) to open the same cube on
  a bigger one.

On delfos, an optional extra nothing depends on (the site's `/api/solve`):

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
nix flake check           # the proofs (and BendTT's verdict), every module, the 3D turns
```

On delfos the extra runs as systemd user units (`elcubodeedgar.service`,
`elcubodeedgar-solver.service`, `elcubodeedgar-watchdog.timer`, and
`elcubodeedgar-tunnel.service`, the reverse tunnel xty's `/api/` goes
through); copies are in `deploy/`.

`probe/site-test.sh WWW PORT` serves the site as xty does (nginx, the same
headers); `probe/bench.html` and `probe/bench.sh` time the device's solver in
headless Chrome with 1, 2, 4, 8 workers, each answer checked by
`probe/Check.bend`; `probe/shot.mjs` takes screenshots (`DPR=3 node
probe/shot.mjs URL 390x844 ...` for a phone); `probe/turns.mjs` checks that the
3D view's turns move the stickers as `Cube.bend` does; `probe/solve-tests.sh`
asks delfos's solver as a visitor would.
