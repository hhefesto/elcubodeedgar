// El cubo de Edgar's solver on the visitor's device: one Web Worker, a thin
// shim around Dev.bend (dev.mjs), which does the thinking. solver.js sends
// {sab} once (the tables, shared by every worker), then jobs {id, op, ...};
// each is answered {id, out}: Dev.bend's answer as it gives it.
//
// A cube's root (its stickers read by Guard.bend) is made afresh for every
// job: Bend's values are used once, and a call may take its arguments apart.
import D from "./dev.mjs";

let t = null;
// the root's node (Kd.bend: coordinates, exact distances) of the cube whose
// subtrees this worker searches, kept: Bend's JavaScript changes arrays in
// place, never such a value, and finding it again costs a bound's 3,240 jobs
let ndKey = null;
let nd = null;

onmessage = ({ data: m }) => {
  if (m.sab) {
    t = new Uint32Array(m.sab);
    postMessage({ id: m.id, out: "" });
    return;
  }
  let out = "";
  try {
    if (m.op === "cptw") D["dv.build.cptw"](t);
    else if (m.op === "e") D["dv.build.e"](t, m.i, m.n);
    else if (m.op === "prefixes") out = D["dv.prefixes"](3);
    else if (m.op === "h") out = String(D["dv.h"](t, D["dv.root"](m.s)).snd);
    else if (m.op === "two") out = D["dv.two"](t, D["dv.root"](m.s), m.a).snd;
    else if (m.op === "bound") out = D["dv.bound"](t, D["dv.root"](m.s), m.b).snd;
    else if (m.op === "sub") {
      if (m.s !== ndKey) {
        nd = D["dv.nd"](t, D["dv.root"](m.s)).snd;
        ndKey = m.s;
      }
      out = D["dv.subk"](t, D["dv.root"](m.s), nd, m.p, m.b).snd;
    }
  } catch (e) {
    out = "error\n" + String(e).slice(0, 200) + "\n0";
  }
  postMessage({ id: m.id, out });
};
