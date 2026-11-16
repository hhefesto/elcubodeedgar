// Probe (Kd.bend's layout): Dev.bend compiled to JavaScript (dev.mjs), on one thread under bun:
// the tables as the page has them (korf.bin and lite.bin placed at their
// offsets, Coord.bend's move tables made here), then for each cube its
// three two-phase answers and the shortest by bounds (whole, or split by
// the three-move prefixes). Every answer is Dev.bend's, checked by it.
//
//   bun probe/devt2.mjs DEV.mjs KORF FST LITE MAXBOUND CUBE...  (a cube: moves, "3.0.6")
// (the corners: KORF's first 11,022,480 words, at Kd.bend's kd.PC; FST at kd.P)
import { readFileSync } from "node:fs";
const [devPath, korf, fst, lite, maxb, ...cubes] = process.argv.slice(2);
const D = (await import(devPath)).default;
const t0 = performance.now();
const ms = () => Math.round(performance.now() - t0);
const len = D["dv.len"]();
const t = new Uint32Array(len);
t.set(new Uint32Array(readFileSync(korf).buffer.slice(0), 0, 11022480), 1048576);
t.set(new Uint32Array(readFileSync(fst).buffer.slice(0)), 12071056);
t.set(new Uint32Array(readFileSync(lite).buffer.slice(0)), 35000000);
console.log(`tables read: ${len} words, ${ms()} ms`);
D["dv.build.cptw"](t);
console.log(`corner moves made: ${ms()} ms`);
const pre = D["dv.prefixes"](3).split(" ");
console.log(`prefixes: ${pre.length}`);
for (const m of cubes) {
  // the cube's facelets, from its moves (Cube.bend, through Dev.bend's import)
  const s = D["Cube:cube.facelets"](D["Cube:cube.apply"](D["Cube:cube.read"](m).value, D["Cube:cube.solved"]()));
  const r = D["dv.root"](s);
  let a = performance.now();
  for (const ax of [0, 1, 2]) {
    const out = D["dv.two"](t, r, ax).snd.split("\n");
    console.log(`  two-phase axis ${ax}: ${out[0]} ${out[2]} moves, ${Math.round(performance.now() - a)} ms`);
    a = performance.now();
  }
  const h = D["dv.h"](t, r).snd;
  const nd = D["dv.nd"](t, r).snd; // the root's node, kept (as solver-worker.js does)
  let found = null, nodes = 0;
  const b0 = performance.now();
  for (let b = h; b <= Number(maxb) && !found; b++) {
    const bt = performance.now();
    if (b < 11) {
      const [w, mv, n] = D["dv.bound"](t, r, b).snd.split("\n");
      nodes += Number(n);
      if (w !== "none") found = [w, mv, b];
    } else {
      for (const p of pre) {
        const [w, mv, n] = D["dv.subk"](t, r, nd, p, b).snd.split("\n");
        nodes += Number(n);
        if (w !== "none") { found = [w, mv, b]; break; }
      }
    }
    console.log(`  bound ${b}: ${found ? found[0] + " " + found[1] : "none"}, ${Math.round(performance.now() - bt)} ms`);
  }
  console.log(`${m} (${m.split(".").length}): h ${h}, ${found ? "shortest " + found[2] + ": " + found[0] : "none up to " + maxb}, ${nodes} nodes, ${Math.round(performance.now() - b0)} ms, ${Math.round(nodes / ((performance.now() - b0) / 1000))} nodes/s`);
}
