// El cubo de Edgar's solver on the visitor's device: the thin JS around it.
// Web Workers, one per core (navigator.hardwareConcurrency), each running
// Dev.bend (solver-worker.js); Sched.bend decides what they do and what the
// page is told. This file only starts the workers, puts the tables into one
// SharedArrayBuffer they all read (downloaded once from the site, brotli or
// gzip, and kept in the Cache API; the move tables made by the workers, split
// between them), gives Sched's jobs to whichever worker is free (so a bound's
// subtrees spread over every core), and passes Sched's answers to the page.
//
// A device that cannot (no SharedArrayBuffer: the page is not cross-origin
// isolated, or a worker failed) asks the site's own solver instead
// (/api/solve), where there is one.
import S from "./sched.mjs";

const CACHE = "elcubo-tables";

export function makeSolver(opts = {}) {
  const cores = Math.max(1, Math.min(opts.workers || navigator.hardwareConcurrency || 4, 16));
  const isolated = globalThis.crossOriginIsolated === true && typeof SharedArrayBuffer === "function";
  let sched = S["sc.init"]();
  let sab = null;
  let booting = null;
  let failed = isolated ? null : "this page is not cross-origin isolated";
  let prefixes = [];
  const ready = { lite: false, korf: false, cptw: false, e: 0, es: cores };
  const build = []; // the tables' jobs, first
  const twos = []; // two-phase jobs: need lite and the corners' moves
  const korfs = []; // the shortest search's: need every table
  const pool = []; // {w, job, up}
  let gen = 0;
  let key = "";
  let dones = [];
  let ticker = null;
  let jobId = 0;
  let lastAsk = "";
  const loads = { lite: 0, korf: 0, via: {}, ms: {}, built: 0 };
  const t00 = performance.now();

  const now = () => Math.round(performance.now());
  const say = (text) => {
    const t = text.replace(/\|/g, "\n");
    for (const d of dones) d(t);
  };

  // Sched's commands, one a line
  const run = (cmds) => {
    for (const line of cmds.split("\n")) {
      if (!line) continue;
      const sp = line.indexOf(" ");
      const c = sp < 0 ? line : line.slice(0, sp);
      const a = sp < 0 ? [] : line.slice(sp + 1).split(" ");
      if (c === "job") {
        if (a[0] === "subs") for (const p of prefixes) korfs.push({ gen, op: "sub", s: key, p, b: Number(a[1]) });
        else if (a[0] === "two") twos.push({ gen, op: "two", s: key, a: Number(a[1]) });
        else if (a[0] === "h") korfs.push({ gen, op: "h", s: key });
        else if (a[0] === "bound") korfs.push({ gen, op: "bound", s: key, b: Number(a[1]) });
      } else if (c === "say") say(line.slice(4));
      else if (c === "end") {
        dones = [];
        clearInterval(ticker);
        ticker = null;
      } else if (c === "stop") stopJobs();
    }
    dispatch();
  };
  const event = (ev) => {
    const r = S["sc.on"](sched, ev);
    sched = r.fst;
    run(r.snd);
  };

  // Workers
  const addWorker = (slot) =>
    new Promise((ok, no) => {
      const w = new Worker(new URL("solver-worker.js", document.baseURI), { type: "module" });
      const e = { w, job: null, up: false };
      w.onerror = (x) => no(new Error("a solver worker failed: " + (x.message || "")));
      w.onmessage = ({ data }) => {
        if (!e.up) {
          e.up = true;
          ok(e);
          dispatch();
          return;
        }
        const job = e.job;
        e.job = null;
        done(job, data.out);
        dispatch();
      };
      w.postMessage({ sab, id: 0 });
      if (slot === undefined) pool.push(e);
      else pool[slot] = e;
    });

  // drop every job not done: the queue, and the workers' (a fresh worker
  // takes a busy one's place; the tables stay, shared)
  const stopJobs = () => {
    gen++;
    twos.length = 0;
    korfs.length = 0;
    pool.forEach((e, i) => {
      if (e.job && e.job.gen !== undefined) {
        e.w.terminate();
        addWorker(i).catch(fail);
      }
    });
  };

  const usable = () => ready.cptw && ready.lite;
  const searchable = () => usable() && ready.korf && ready.e === ready.es;
  const dispatch = () => {
    for (const e of pool) {
      if (!e.up || e.job) continue;
      const job = build.shift() || (usable() && twos.shift()) || (searchable() && korfs.shift());
      if (!job) return;
      e.job = job;
      e.w.postMessage({ ...job, id: ++jobId });
    }
  };

  const done = (job, out) => {
    if (out.startsWith("error\n")) return fail(new Error(out.split("\n")[1]));
    if (job.op === "prefixes") prefixes = out.split(" ");
    else if (job.op === "cptw") ready.cptw = true;
    else if (job.op === "e") ready.e++;
    if (ready.cptw && ready.e === ready.es && !loads.built) loads.built = Math.round(performance.now() - t00);
    if (job.gen === undefined || job.gen !== gen) return;
    const [w, mv, n] = out.split("\n");
    if (job.op === "two") event(`two ${now()} ${w} ${mv} ${n}`);
    else if (job.op === "h") event(`h ${now()} ${out}`);
    else event(`res ${now()} ${job.b} ${w} ${mv} ${n}`);
  };

  const fail = (x) => {
    failed = String(x && x.message ? x.message : x);
    console.error("solver:", failed);
    const ds = dones;
    dones = [];
    clearInterval(ticker);
    ticker = null;
    for (const d of ds) fallback(lastAsk, d);
  };

  // A table's bytes, fetched
  const fetchAll = async (url, name, size) => {
    const r = await fetch(url);
    if (!r.ok) throw new Error(`${name} tables: ${r.status}`);
    const parts = [];
    let got = 0;
    const rd = r.body.getReader();
    for (;;) {
      const { done: end, value } = await rd.read();
      if (end) break;
      parts.push(value);
      got += value.length;
      loads[name] = Math.min(0.99, got / size);
    }
    const all = new Uint8Array(got);
    let at = 0;
    for (const p of parts) {
      all.set(p, at);
      at += p.length;
    }
    return all;
  };
  const gunzip = async (bytes) =>
    new Uint8Array(await new Response(new Blob([bytes]).stream().pipeThrough(new DecompressionStream("gzip"))).arrayBuffer());

  // A table: from the Cache API, or downloaded (and kept); into the shared
  // array. Downloaded: the .br file, sent with Content-Encoding br so the
  // browser undoes it; if what comes is not the table's size (something on
  // the way would not pass brotli), the .gz one, undone here.
  const load = async (name, f, keep) => {
    const t0 = performance.now();
    const size = f.words * 4;
    const url = new URL(f.br, document.baseURI).href;
    let buf = null;
    let cache = null;
    try {
      cache = await caches.open(CACHE);
      const hit = await cache.match(url);
      if (hit) {
        buf = new Uint8Array(await hit.arrayBuffer());
        loads.via[name] = "cache";
      }
    } catch {}
    if (!buf || buf.length !== size) {
      buf = await fetchAll(url, name, size);
      loads.via[name] = "br";
      if (buf.length !== size) {
        buf = await gunzip(await fetchAll(new URL(f.gz, document.baseURI).href, name, size));
        loads.via[name] = "gz";
      }
      if (buf.length !== size) throw new Error(`${name} tables: ${buf.length} bytes, not ${size}`);
      if (cache) await cache.put(url, new Response(buf)).catch(() => {});
    }
    new Uint32Array(sab).set(new Uint32Array(buf.buffer, buf.byteOffset, f.words), f.at);
    loads[name] = 1;
    loads.ms[name] = Math.round(performance.now() - t0);
    keep.push(url);
  };
  // tables of older versions, no longer named in tables.json, forgotten
  const tidy = async (keep) => {
    try {
      const cache = await caches.open(CACHE);
      for (const req of await cache.keys()) if (!keep.includes(req.url)) await cache.delete(req);
    } catch {}
  };

  const boot = () => {
    if (booting) return booting;
    booting = (async () => {
      const man = await (await fetch(new URL("tables.json", document.baseURI), { cache: "no-cache" })).json();
      sab = new SharedArrayBuffer(man.words * 4);
      await Promise.all(Array.from({ length: cores }, () => addWorker()));
      // Coord.bend's move tables, made here: the edges' rows split over the workers
      build.push({ op: "prefixes" }, { op: "cptw" });
      const rows = 665280;
      for (let k = 0; k < cores; k++) {
        const i = Math.floor((rows * k) / cores);
        build.push({ op: "e", i, n: Math.floor((rows * (k + 1)) / cores) - i });
      }
      dispatch();
      const keep = [];
      await load("lite", man.lite, keep);
      ready.lite = true;
      dispatch();
      await load("korf", man.korf, keep);
      ready.korf = true;
      dispatch();
      tidy(keep);
    })().catch(fail);
    return booting;
  };

  // No solver here: the site's, if it has one, asked again while its answer
  // is not final (as the page used to)
  const fallback = (arg, d, tries = 0) => {
    if (arg !== lastAsk) return;
    const [, moves, who] = arg.split(" ");
    fetch(`/api/solve?m=${moves || ""}&v=${who || ""}`)
      .then((r) => (r.ok ? r.text() : Promise.reject(new Error(String(r.status)))))
      .then(
        (body) => {
          const w = body.split("\n")[0];
          d(body);
          // (a "down" the page itself asks again for)
          if ((w === "working" || w === "queued") && tries < 80) setTimeout(() => fallback(arg, d, tries + 1), 300);
        },
        () => d(`nodevice\n0\n0\nok\n0\n${failed || ""}\n`),
      );
  };

  // the cube, and the way back already known (the position's moves undone,
  // from the page): a short way like two-phase's, so no answer is longer
  const start = (fl, inv) => {
    if (fl !== key || failed) return;
    if (!prefixes.length) return setTimeout(() => start(fl, inv), 50);
    event(`start ${now()} ${cores} ${prefixes.length} ${fl}`);
    if (inv) event(`two ${now()} ok ${inv} ${inv.split(".").length}`);
  };

  return {
    cores,
    isolated,
    loads,
    failed: () => failed,
    // arg: "FACELETS MOVES WHO INVERSE" (the cube's stickers; the moves that
    // make it, for the site's solver; the page's name; those moves undone).
    // d: told each answer
    solve(arg, d) {
      lastAsk = arg;
      if (failed) return fallback(arg, d);
      boot();
      const [fl, , , inv] = arg.split(" ");
      if (fl !== key) {
        key = fl;
        dones = [d];
      } else if (!dones.includes(d)) dones.push(d);
      if (!ticker) ticker = setInterval(() => event(`tick ${now()}`), 500);
      start(fl, inv);
    },
  };
}
