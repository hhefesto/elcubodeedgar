// "Enter your own cube": the thin JS around it. The visitor paints the 54
// stickers on a flat net (a colour, then a sticker; the centres are fixed) or
// reads them with the camera, a face at a time (each photo's 3 x 3 guide square
// handed to Dev.bend's dv.photo, which gives each sticker the colour of the
// centre it looks most like), then fixes what is wrong by painting. Dev.bend
// decides everything: whether the stickers can be a real cube (dv.check,
// Guard.bend: plainly why not, if not), how to hold the cube for each photo
// (dv.hold), and, from a short solution the device's solver finds, the moves
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
  const say = (t, bad) => {
    msg.textContent = t;
    msg.classList.toggle("bad", !!bad);
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
    draw();
    say("");
  });

  // the camera: six photos, in Photo.bend's order (F R B L U D)
  let stream = null;
  let shots = [];
  const stop = () => {
    stream?.getTracks().forEach((t) => t.stop());
    stream = null;
    cam.hidden = true;
  };
  const askHold = async () => {
    const d = await dev();
    holdText.textContent = `Photo ${shots.length + 1} of 6: ${d["dv.hold"](shots.length)} Fill the square with the face.`;
  };
  document.getElementById("own-cam").addEventListener("click", async () => {
    try {
      stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment" }, audio: false });
    } catch (x) {
      return say("The camera could not be opened (" + (x.message || x.name || "no permission") + "). Paint the stickers instead.", true);
    }
    video.srcObject = stream;
    await video.play().catch(() => {});
    shots = [];
    cam.hidden = false;
    say("");
    askHold();
  });
  document.getElementById("own-cam-stop").addEventListener("click", stop);
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
  document.getElementById("own-shot").addEventListener("click", async () => {
    if (!video.videoWidth) return;
    shots.push(photo());
    if (shots.length < 6) return askHold();
    stop();
    const d = await dev();
    const read = d["dv.photo"](shots.join("\n"));
    // the centres stay fixed; the rest as the photos read
    stickers = [...read].map((x, k) => (k % 9 === 4 ? FACES[Math.floor(k / 9)] : FACES.includes(x) ? x : "U"));
    draw();
    const why = d["dv.check"](stickers.join(""));
    say(why ? "Read from the photos. Check it against your cube and fix it by painting: " + why : "Read from the photos. Check it against your cube, then press Solve this cube.", !!why);
  });

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
