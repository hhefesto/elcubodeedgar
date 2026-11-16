// "Enter your own cube": the thin JS around it. The visitor paints the 54
// stickers on a flat net (a colour, then a sticker; the centres are fixed) or
// reads them with the camera, a face at a time (each photo's 3 x 3 guide square
// handed to Dev.bend's dv.photo, which gives each sticker the colour of the
// centre it looks most like), then fixes what is wrong by painting. Dev.bend
// decides everything: whether the stickers can be a real cube (dv.check,
// Guard.bend: plainly why not, if not), how to hold the cube for each photo
// (dv.hold, dv.pose), what the camera sees (dv.seen), a face taken twice
// (dv.twin), and, from a short solution the device's solver finds, the moves
// that make the cube (dv.undo); the page then shows that position (#m=) and
// solves it as any other.
const FACES = "URFDLB";
const SOLVED = [...FACES].map((f) => f.repeat(9)).join("");
// where face f's sticker i sits on the net (12 x 9 cells): U above F, then
// L F R B, then D (Cube.bend's facelet layout)
const AT = { U: [0, 3], L: [3, 0], F: [3, 3], R: [3, 6], B: [3, 9], D: [6, 3] };

export function ownCube({ solver, go }) {
  const dlg = document.getElementById("own-dlg");
  const net = document.getElementById("own-net");
  const msg = document.getElementById("own-msg");
  const cam = document.getElementById("own-cam-box");
  const video = document.getElementById("own-video");
  const holdText = document.getElementById("own-hold");
  let stickers = [...SOLVED];
  let brush = "U";
  let D = null;
  const dev = async () => (D ??= (await import(new URL("dev.mjs", document.baseURI).href)).default);
  // what the panel says: by the camera's buttons while the camera is on
  const camMsg = document.getElementById("own-cam-msg");
  const say = (t, bad) => {
    const m = cam.hidden ? msg : camMsg;
    for (const e of [msg, camMsg]) e.textContent = "";
    m.textContent = t;
    m.classList.toggle("bad", !!bad);
  };

  // the net
  const cells = [];
  for (let k = 0; k < 54; k++) {
    const f = FACES[Math.floor(k / 9)];
    const i = k % 9;
    const b = document.createElement("button");
    b.type = "button";
    b.className = "own-st" + (i === 4 ? " centre" : "");
    b.style.gridRow = String(AT[f][0] + Math.floor(i / 3) + 1);
    b.style.gridColumn = String(AT[f][1] + (i % 3) + 1);
    b.setAttribute("aria-label", `${f} face, sticker ${i + 1}${i === 4 ? " (the centre, fixed)" : ""}`);
    if (i !== 4)
      b.addEventListener("click", () => {
        stickers[k] = brush;
        draw();
      });
    net.appendChild(b);
    cells.push(b);
  }
  const draw = () => cells.forEach((b, k) => (b.dataset.face = stickers[k]));
  for (const p of document.querySelectorAll("#own-pal button"))
    p.addEventListener("click", () => {
      brush = p.dataset.face;
      for (const q of document.querySelectorAll("#own-pal button")) q.setAttribute("aria-checked", String(q === p));
    });
  draw();

  document.getElementById("own-clear").addEventListener("click", () => {
    stickers = [...SOLVED];
    shots = Array(6).fill(null);
    seen = Array(6).fill(null);
    draw();
    say("");
  });

  // The camera: six photos, a face each, in Photo.bend's order (F R B L U D).
  // Dev.bend decides how to hold the cube for each (dv.hold, said; dv.pose,
  // drawn), what the camera sees on each sticker (dv.seen: a dot of that
  // colour on each), whether a photo is a face already taken (dv.twin: the
  // cube was not turned), and the cube the six make (dv.photo). Photos are
  // kept if the camera is stopped, until the six are read.
  const NAME = { U: "white", R: "red", F: "green", D: "yellow", L: "orange", B: "blue" };
  const LETTER = Object.fromEntries(Object.entries(NAME).map(([f, n]) => [n, f]));
  const view = document.getElementById("own-view");
  const guide = document.getElementById("own-guide");
  const steps = document.getElementById("own-steps");
  const pose = document.getElementById("own-pose");
  const kText = document.getElementById("own-k");
  const turnText = document.getElementById("own-turn");
  const shotBtn = document.getElementById("own-shot");
  const keepBtn = document.getElementById("own-keep");
  const backBtn = document.getElementById("own-back");
  let stream = null;
  let live = 0;
  let shots = Array(6).fill(null);
  let seen = Array(6).fill(null);
  let at = 0;
  let held = null;
  let poses = null;

  const stop = () => {
    clearInterval(live);
    live = 0;
    stream?.getTracks().forEach((t) => t.stop());
    stream = null;
    video.srcObject = null;
    held = null;
    keepBtn.hidden = true;
    cam.hidden = true;
    dlg.classList.remove("cam");
  };

  // the 3 x 3 square: a dot on each sticker, the centre's ringed in its colour
  const dots = [];
  for (let i = 0; i < 9; i++) {
    const c = document.createElement("i");
    if (i === 4) c.className = "c";
    guide.appendChild(c);
    dots.push(c);
  }
  const rgb = (s) => {
    const n = s.split(" ").map(Number);
    return [...Array(9)].map((_, i) => `rgb(${n[3 * i]},${n[3 * i + 1]},${n[3 * i + 2]})`);
  };

  // the six steps: the face's colour along the bottom, then what was read
  const chips = [];
  for (let k = 0; k < 6; k++) {
    const li = document.createElement("li");
    const b = document.createElement("button");
    b.type = "button";
    b.innerHTML = `<span class="n">${k + 1}</span><span class="th">${"<i></i>".repeat(9)}</span>`;
    b.addEventListener("click", () => {
      if (stream) ask(k);
    });
    li.appendChild(b);
    steps.appendChild(li);
    chips.push(b);
  }

  // the cube held for photo k, drawn: front (at the left), top, right; only
  // the centres in colour (a face is its centre's colour), and the turn to it
  const SVGNS = "http://www.w3.org/2000/svg";
  const el = (tag, attrs) => {
    const e = document.createElementNS(SVGNS, tag);
    for (const [a, v] of Object.entries(attrs)) e.setAttribute(a, v);
    return e;
  };
  const face = (o, u, v, f) =>
    [...Array(9)].map((_, k) => {
      const i = k % 3;
      const j = Math.floor(k / 3);
      const pt = (a, b) => [o[0] + a * u[0] + b * v[0], o[1] + a * u[1] + b * v[1]].map((x) => x.toFixed(1)).join(",");
      const e = 0.08;
      const [a0, a1, b0, b1] = [(i + e) / 3, (i + 1 - e) / 3, (j + e) / 3, (j + 1 - e) / 3];
      const p = el("polygon", { class: "st", points: [pt(a0, b0), pt(a1, b0), pt(a1, b1), pt(a0, b1)].join(" ") });
      if (k === 4) p.style.fill = `var(--${f})`;
      return p;
    });
  const arrow = (s, c, t) => {
    const g = el("g", {});
    g.appendChild(el("path", { class: "arw", d: `M${s} Q${c} ${t}` }));
    const [tx, ty] = t.split(",").map(Number);
    const [cx, cy] = c.split(",").map(Number);
    const l = Math.hypot(tx - cx, ty - cy);
    const [dx, dy] = [(tx - cx) / l, (ty - cy) / l];
    const pts = [[tx + 7 * dx, ty + 7 * dy], [tx - 6 * dy, ty + 6 * dx], [tx + 6 * dy, ty - 6 * dx]];
    g.appendChild(el("polygon", { class: "arh", points: pts.map((p) => p.map((x) => x.toFixed(1)).join(",")).join(" ") }));
    return g;
  };
  const drawPose = (k) => {
    const [f, u, r] = poses[k];
    pose.replaceChildren(
      el("polygon", { class: "face", points: "60,8 105,34 105,86 60,112 15,86 15,34" }),
      ...face([17, 35], [43, -25], [43, 25], u),
      ...face([17, 35], [43, 25], [0, 50], f),
      ...face([60, 60], [43, -25], [0, 50], r),
    );
    // a quarter to the left (2..4); tip the top toward you (5); the bottom (6)
    if (k >= 1 && k <= 3) pose.appendChild(arrow("96,13", "60,-14", "24,13"));
    if (k === 4) pose.appendChild(arrow("6,32", "-6,62", "6,92"));
    if (k === 5) pose.appendChild(arrow("6,92", "-6,62", "6,32"));
  };

  // how to hold it, said: its colours with a chip each; the turn apart
  const sayHold = (t) => {
    const m = t.match(/^(.*?)\s*\((.*)\)\.?$/);
    const main = m ? m[1].replace(/[,.]?$/, ".") : t;
    holdText.replaceChildren(
      ...main.split(/\b(white|red|green|yellow|orange|blue)\b/).map((w, i) => {
        if (i % 2 === 0) return document.createTextNode(w);
        const b = document.createElement("b");
        const c = document.createElement("span");
        c.className = "own-chip";
        c.style.setProperty("--c", `var(--${LETTER[w]})`);
        b.append(c, w);
        return b;
      }),
    );
    turnText.textContent = m ? m[2][0].toUpperCase() + m[2].slice(1) + "." : "";
  };

  const drawSteps = () =>
    chips.forEach((b, k) => {
      b.classList.toggle("done", !!shots[k]);
      b.classList.toggle("now", k === at);
      b.style.setProperty("--c", `var(--${poses[k][0]})`);
      b.setAttribute("aria-label", `photo ${k + 1}, the ${NAME[poses[k][0]]} face${shots[k] ? ", taken: tap to take it again" : ""}`);
      if (seen[k]) rgb(seen[k]).forEach((c, i) => (b.querySelectorAll(".th i")[i].style.background = c));
    });

  const ask = async (k) => {
    const d = await dev();
    at = k;
    held = null;
    keepBtn.hidden = true;
    kText.textContent = `Photo ${k + 1} of 6 · the ${NAME[poses[k][0]]} face`;
    sayHold(d["dv.hold"](k));
    drawPose(k);
    dots[4].style.setProperty("--ring", `var(--${poses[k][0]})`);
    shotBtn.textContent = shots[k] ? `Take photo ${k + 1} again` : `Take photo ${k + 1}`;
    backBtn.disabled = k === 0;
    drawSteps();
  };

  // what the camera sees on each sticker, five times a second
  const tick = () => {
    if (!stream || !video.videoWidth || document.hidden || !D) return;
    try {
      rgb(D["dv.seen"](photo())).forEach((c, i) => dots[i].style.setProperty("--seen", c));
    } catch {}
  };

  document.getElementById("own-cam").addEventListener("click", async () => {
    if (!navigator.mediaDevices?.getUserMedia)
      return say("This browser lets the page use no camera (it needs https, and a browser that allows it). Paint the stickers instead.", true);
    say("Opening the camera...");
    try {
      stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment", width: { ideal: 1280 }, height: { ideal: 1280 } }, audio: false });
    } catch (x) {
      return say("The camera could not be opened (" + (x.message || x.name || "no permission") + "). Paint the stickers instead.", true);
    }
    // a camera that faces you is shown as a mirror (the photos are not)
    const mirror = stream.getVideoTracks()[0]?.getSettings?.().facingMode !== "environment";
    view.classList.toggle("mirror", mirror);
    steps.classList.toggle("mirror", mirror);
    video.srcObject = stream;
    await video.play().catch(() => {});
    const d = await dev();
    poses ??= [0, 1, 2, 3, 4, 5].map((k) => [...d["dv.pose"](k)]);
    dlg.classList.add("cam");
    cam.hidden = false;
    dlg.scrollTop = 0;
    say("");
    const next = shots.findIndex((s) => !s);
    ask(next < 0 ? 0 : next);
    live = setInterval(tick, 200);
  });
  document.getElementById("own-cam-stop").addEventListener("click", () => {
    stop();
    const n = shots.filter(Boolean).length;
    say(n ? `The camera is off; ${n} of 6 photos kept for when it is on again.` : "");
  });
  backBtn.addEventListener("click", () => {
    if (at > 0) ask(at - 1);
  });

  // the guide square (the middle of the picture, 60% of its shorter side), as
  // 36 x 36 pixels, each channel a char (256 + value): Photo.bend's form
  const photo = () => {
    const w = video.videoWidth;
    const h = video.videoHeight;
    const side = Math.round(Math.min(w, h) * 0.6);
    const c = document.createElement("canvas");
    c.width = c.height = 36;
    const g = c.getContext("2d", { willReadFrequently: true });
    g.drawImage(video, Math.round((w - side) / 2), Math.round((h - side) / 2), side, side, 0, 0, 36, 36);
    const px = g.getImageData(0, 0, 36, 36).data;
    let s = "";
    for (let i = 0; i < px.length; i += 4) s += String.fromCharCode(256 + px[i], 256 + px[i + 1], 256 + px[i + 2]);
    return s;
  };

  // the six read at once, onto the net, to check and fix by painting
  const readAll = async () => {
    const d = await dev();
    stop();
    let read;
    try {
      read = d["dv.photo"](shots.join("\n"));
    } catch (x) {
      console.error(x);
      return say("The photos could not be read (" + (x.message || x) + "). Paint the stickers instead.", true);
    }
    shots = Array(6).fill(null);
    seen = Array(6).fill(null);
    // the centres stay fixed; the rest as the photos read
    stickers = [...read].map((x, k) => (k % 9 === 4 ? FACES[Math.floor(k / 9)] : FACES.includes(x) ? x : "U"));
    draw();
    net.classList.remove("fresh");
    void net.offsetWidth;
    net.classList.add("fresh");
    net.scrollIntoView({ block: "center", behavior: "smooth" });
    const why = d["dv.check"](stickers.join(""));
    say(
      why
        ? "Read from your six photos, but it is not a cube yet: " + why + " Tap the stickers it got wrong to fix them, or take the photos again."
        : "Read from your six photos. Check each face against your cube (fix a sticker by tapping it), then press Solve this cube.",
      !!why,
    );
  };

  const keep = async (s) => {
    const d = await dev();
    shots[at] = s;
    seen[at] = d["dv.seen"](s);
    held = null;
    keepBtn.hidden = true;
    say("");
    view.classList.remove("snap");
    void view.offsetWidth;
    view.classList.add("snap");
    const next = [1, 2, 3, 4, 5].map((i) => (at + i) % 6).find((k) => !shots[k]);
    if (next === undefined) {
      drawSteps();
      return readAll();
    }
    ask(next);
  };
  shotBtn.addEventListener("click", async () => {
    if (!stream) return;
    if (!video.videoWidth) return say("The camera is still starting: a moment, then take it.");
    const d = await dev();
    const s = photo();
    // the same face as a photo already taken: the cube was not turned
    const others = [0, 1, 2, 3, 4, 5].filter((j) => j !== at && shots[j]);
    let twin = 6;
    try {
      twin = d["dv.twin"]([...others.map((j) => shots[j]), s].join("\n"));
    } catch {}
    if (twin < others.length) {
      const j = others[twin];
      held = s;
      keepBtn.hidden = false;
      return say(`That looks like photo ${j + 1} again, the ${NAME[poses[j][0]]} face. Show the ${NAME[poses[at][0]]} centre (the drawing shows how), then take it again.`, true);
    }
    keep(s);
  });
  keepBtn.addEventListener("click", () => held && keep(held));

  // a short way for the cube (the device's solver), undone: the moves that make it
  const wayFor = (fl) =>
    new Promise((ok, no) => {
      let done = false;
      solver().solve(`${fl} x own`, (text) => {
        if (done) return;
        const ls = text.split("\n");
        const w = ls[0];
        if (["busy", "cancelled", "none", "nodevice", "queued", "down"].includes(w)) {
          done = true;
          return no(new Error(w === "nodevice" ? ls[5] || w : w));
        }
        const moves = ["working", "short", "quick", "late"].includes(w) ? ls[5] : w;
        if (moves === undefined || ls[3] !== "ok") return;
        done = true;
        ok(moves);
      });
    });
  document.getElementById("own-go").addEventListener("click", async () => {
    const fl = stickers.join("");
    const d = await dev();
    const why = d["dv.check"](fl);
    if (why) return say("This cannot be a real cube: " + why, true);
    if (fl === SOLVED) return say("That is the solved cube: paint the stickers as your cube has them.", true);
    say("Checked: a real cube. Finding it a way back...");
    try {
      const moves = await wayFor(fl);
      stop();
      dlg.close();
      go(d["dv.undo"](moves));
    } catch (x) {
      say("The solver could not start here: " + (x.message || x), true);
    }
  });
  dlg.addEventListener("close", stop);
  return { open: () => dlg.showModal() };
}
