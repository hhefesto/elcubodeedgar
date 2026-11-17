// El cubo de Edgar's "Solve it your way": the ways people solve a cube (CFOP,
// CFOP with a four-look last layer, the beginner's), worked out on the
// visitor's device by Ways.bend (ways.mjs), in a Web Worker of its own so the
// page never waits on it. A thin shim: the tables (2^20 words, under a second)
// are made at the first job and kept; each job is a position's moves
// ("3.10.17"), answered {id, out}, Ways.bend's lines as it gives them.
import W from "./ways.mjs";

let t = null;

onmessage = ({ data: m }) => {
  let out = "";
  try {
    t ??= W["wy.tables"]();
    const r = W["wy.ways"](t, m.s);
    t = r.fst;
    out = r.snd;
  } catch (e) {
    t = null;
    out = "error|" + String(e).slice(0, 200);
  }
  postMessage({ id: m.id, out });
};
