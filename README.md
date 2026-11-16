# Edgar's Rubik's cube

https://edgarsrubicscube.hhefesto.dev: scramble a cube in 3D, and step through
its optimal solution, one animated turn at a time.

Everything that thinks is Bend:

- `Cube.bend`: the cube as a group element (Kociemba's cubie level), its moves,
  notation and stickers.
- `Coord.bend`, `Search.bend`, `Par.bend`, `Solve.bend`: Korf's optimal solver,
  IDA* over three tables of exact distances (the corners; two sets of six edges),
  every bound from 9 on searched on all 8 cores.
- `Server.bend`: the web server, the page's files and `GET /api/solve?m=...`;
  every answer is checked by `Cube.bend` before it goes out.
- `web/App.bend`: the page, a bend-frp app; it holds the cube and tells the 3D
  view (`web/cube3d.js`, three.js) which turn to animate and what the stickers
  are after it.
- `Group.bend`, `LAWS.bend`, `PROOF.bend`: the group theory the solver stands
  on, as laws, each proven (`bend PROOF.bend`).

```
nix build                 # the server with the page: result/bin/edgarsrubicscube [PORT]
nix flake check           # the proofs (and BendTT's verdict), every module, the 3D turns
```

`probe/turns.mjs` checks that the 3D view's turns move the stickers as
`Cube.bend` does, for all 18 moves.
