# El cubo de Edgar

Edgar's Rubik's cube, https://elcubodeedgar.hhefesto.dev: scramble a cube in
3D, or turn its faces yourself, and step through its optimal solution, one
animated turn at a time.

Everything that thinks is Bend:

- `Cube.bend`: the cube as a group element (Kociemba's cubie level), its moves,
  notation and stickers.
- `Coord.bend`, `Sym.bend`, `Kc.bend`, `Build.bend`: the solver's tables. The
  corners' exact distances (88,179,840 positions), and, as in Kociemba's
  optimal solver, the exact distances of the edges' flips, the four U-D slice
  edges' places and the corners' twists, kept by class under the eight turns
  of the whole cube that keep the U-D axis (3,044,504 classes, 6.66 billion
  positions). `Build.bend` builds them breadth first on 8 cores and writes
  them to a file (3.6 GB, about 25 minutes, 5 GB of memory).
- `Search.bend`, `Opt.bend`, `Fast.bend`: Korf's IDA*, its bound the largest
  of four exact distances (the corners; the edges and twists as the cube is,
  and turned onto its two other axes); every bound from 15 on is searched on
  all 8 cores, a chunk of three-move prefixes at a time.
- `TwoPhase.bend`: a short way back at once, not always the shortest:
  Kociemba's two-phase algorithm (phase 1 into the cubes with edges
  unflipped, corners untwisted and the U-D slice home, by `Kc.bend`'s exact
  table; phase 2 with U, D, R2, L2, F2, B2), on each of the three axes: about
  20-22 moves for a random cube, in under a second. Its length (or the
  scramble's, if shorter) caps the optimal search: once every shorter bound
  has no solution, the short way is a shortest one.
- `Worker.bend`: the solver as a process of its own (`cube-solver`, on
  127.0.0.1:8095): one cube at a time; the same cube asked again from the same
  page joins its search (its 75 s count from the first ask), another cube
  from that page cancels it; at most 6 wait. Every ask is answered within
  20 s: the answer, or "working" (how far the search got, and the short way
  so far), or "queued"; the page asks again, so no request is near Safari's
  60 s or Cloudflare's 100 s. Past 75 s the answer is the short way, marked
  as not proven the shortest, with what the search ruled out. Answers are
  kept a while, so asking again for a cube just answered is instant.
- `Server.bend`: the web server (127.0.0.1:8093): the page's files, and
  `GET /api/solve?m=...&v=...` handed to the solver (v: the page's own name,
  so two people behind one address do not cancel each other), so the page
  always answers. If the solver holds an ask past 45 s, its loop is stuck,
  and the server kills it (systemd starts it again). Every answer is checked by `Cube.bend` before it goes out, and again
  by the page.
- `web/App.bend`: the page, a bend-frp app; it holds the cube and tells the 3D
  view (`web/cube3d.js`, three.js) which turn to animate and what the stickers
  are after it. Random scrambles (12 to 16 moves), turns by hand (the 18
  buttons, or the keys u r f d l b, shift for back), Solve, Next step, Play,
  and "What do these buttons mean?", the moves explained (`web/index.html`).
- `Group.bend`, `LAWS.bend`, `PROOF.bend`: the group theory the solver stands
  on, as laws, each proven (`bend PROOF.bend --verdict`).
- `Solve.bend`, `Par.bend`: the first solver (three tables: the corners, two
  sets of six edges), whose table code the new one builds on.

```
nix build                 # the page's server: result/bin/elcubodeedgar [PORT]
nix build .#solver        # the solver and its tables: elcubodeedgar-solver [PORT]
nix build .#watchdog      # restarts either if its /health stops answering
nix flake check           # the proofs (and BendTT's verdict), every module, the 3D turns
```

On delfos they run as systemd user units: `elcubodeedgar.service`,
`elcubodeedgar-solver.service`, `elcubodeedgar-watchdog.timer` (every 30 s),
and `elcubodeedgar-tunnel.service` (the reverse tunnel to xty, which serves
the site); copies are in `deploy/`.

`probe/turns.mjs` checks that the 3D view's turns move the stickers as
`Cube.bend` does, for all 18 moves; `probe/shot.mjs` takes screenshots in
headless Chrome (`DPR=3 node probe/shot.mjs URL 390x844 ...` for a phone);
`probe/Bench.bend` times the solver on scrambles, each answer checked;
`probe/solve-tests.sh` asks the solver or the site as a visitor would (known
distances, superflip, the same cube twice, a new cube mid-solve, the time
limit, kept answers), each answer checked by `probe/Check.bend`.
