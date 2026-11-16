// The 3D view turns stickers as Cube.bend does: for every move, and for two
// sequences, the stickers geom.js's turns leave equal the ones Cube.bend
// computes (bend probe/Facelets.bend, given on stdin).
//   bend probe/Facelets.bend | node probe/turns.mjs
import { turned } from "../web/geom.js";

const SOLVED = "UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB";
const text = await new Promise((ok) => {
  let s = "";
  process.stdin.on("data", (d) => (s += d));
  process.stdin.on("end", () => ok(s));
});
let bad = 0;
let n = 0;
for (const line of text.trim().split("\n")) {
  const [moves, want] = line.includes("|") ? line.split("|") : line.split(" ");
  const got = moves.trim() === "" ? SOLVED : moves.trim().split(/\s+/).reduce(turned, SOLVED);
  n++;
  if (got !== want) {
    bad++;
    console.log(`DIFFER ${moves}\n  bend ${want}\n  view ${got}`);
  }
}
console.log(bad === 0 ? `all ${n} agree` : `${bad} of ${n} differ`);
process.exit(bad === 0 ? 0 : 1);
