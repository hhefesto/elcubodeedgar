// El cubo de Edgar's solver on the visitor's device, in a Web Worker: a thin
// shim around probe/Local.bend (compiled to local.js), which does the thinking.
// The page sends {tables: URL} once, then {id, s} for a cube (moves from
// solved, "3.10.17"); this answers {kind: "ready"}, then for each cube a
// {kind: "bound"} after every bound with no solution, and {kind: "done"} with
// Local.bend's answer. The page stops a search by terminating the worker.
import L from "./local.js";

let tables = null;

onmessage = async ({ data }) => {
  if (data.tables) {
    const t0 = performance.now();
    const r = await fetch(data.tables);
    if (!r.ok) return postMessage({ kind: "error", why: "the tables: " + r.status });
    tables = new Uint32Array(await r.arrayBuffer());
    return postMessage({ kind: "ready", ms: Math.round(performance.now() - t0), bytes: tables.byteLength });
  }
  const { id, s } = data;
  const t0 = performance.now();
  let nodes = 0;
  for (let b = L["lc.start"](tables, s).snd; b <= 20; b++) {
    const [word, moves, n] = L["lc.bound"](tables, s, b).snd.split("\n");
    nodes += Number(n);
    const ms = Math.round(performance.now() - t0);
    if (word !== "none") return postMessage({ id, kind: "done", word, moves, nodes, ms, bound: b });
    postMessage({ id, kind: "bound", bound: b, nodes, ms });
  }
  postMessage({ id, kind: "done", word: "none", moves: "", nodes, ms: Math.round(performance.now() - t0), bound: 21 });
};
