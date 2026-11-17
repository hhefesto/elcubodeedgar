// Your cube's colors: the thin JS around Scheme.bend, which decides
// everything (the presets, what a key names, a scheme of one's own, a face's
// color picked, the page's words in the visitor's colors). This only
// applies what it says: the page's CSS colors (--U .. --B, the ink on each,
// --sch-name), the 3D cube's (through the hooks), the words of whatever is
// marked data-say, and the picker (#sch-dlg). The scheme is kept in
// localStorage as its key, with what it gave, so a page opens in it at once.
const STORE = "elcubo.colors";
// where it was kept before the page said "color": read once, moved to STORE
const STORE_OLD = "elcubo.colours";
try {
  const old = localStorage.getItem(STORE_OLD);
  if (old !== null) {
    if (localStorage.getItem(STORE) === null) localStorage.setItem(STORE, old);
    localStorage.removeItem(STORE_OLD);
  }
} catch {}
const FACES = "URFDLB";
const STANDARD = { key: "0", name: "Standard", names: ["white", "red", "green", "yellow", "orange", "blue"], css: null, inks: null };

let S = null;
const bend = async () => (S ??= (await import(new URL("scheme.mjs", document.baseURI).href)).default);

const kept = () => {
  try {
    const c = JSON.parse(localStorage.getItem(STORE));
    return c && typeof c.key === "string" && Array.isArray(c.names) ? c : null;
  } catch {
    return null;
  }
};
let cur = kept() ?? STANDARD;
const hooks = [];

// the scheme's shades on the page (none: the stylesheet's, the standard ones)
const paint = () => {
  const st = document.documentElement.style;
  [...FACES].forEach((f, i) => {
    if (cur.css) st.setProperty(`--${f}`, cur.css[i]);
    else st.removeProperty(`--${f}`);
    if (cur.inks) st.setProperty(`--${f}-ink`, cur.inks[i] === "l" ? "var(--paper-3)" : "var(--ink)");
    else st.removeProperty(`--${f}-ink`);
  });
  st.setProperty("--sch-name", JSON.stringify(cur.name));
  document.documentElement.dataset.scheme = cur.key;
};

// the page's words in the scheme's colors: each text node under data-say,
// said again from what it first said
const first = new WeakMap();
const words = () => {
  for (const el of document.querySelectorAll("[data-say]")) {
    const w = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
    for (let n = w.nextNode(); n; n = w.nextNode()) {
      if (!first.has(n)) first.set(n, n.data);
      const t = first.get(n);
      n.data = S && cur.key !== "0" ? S["sc.say"](cur.key, t) : t;
    }
    for (const b of el.querySelectorAll("[data-face][aria-label]")) b.setAttribute("aria-label", name(b.dataset.face));
  }
};

const name = (f) => cur.names[FACES.indexOf(f)] ?? f;

// key's scheme, made the page's; what is wrong with it, or ""
const use = async (key) => {
  const s = await bend();
  const why = s["sc.why"](key);
  if (why) return why;
  cur = {
    key,
    name: s["sc.name.of"](key),
    names: s["sc.names.of"](key).split(" "),
    css: s["sc.css.of"](key).split(" "),
    inks: s["sc.inks.of"](key).split(" "),
  };
  try {
    localStorage.setItem(STORE, JSON.stringify(cur));
  } catch {}
  paint();
  words();
  hooks.forEach((h) => h(cur));
  return "";
};

// The picker: the presets, each as its six centers on a net, its name and
// what it is; under them, a color for each face, for a cube of one's own
const dlg = () => document.getElementById("sch-dlg");
const net = (css) => {
  const n = document.createElement("span");
  n.className = "sch-net";
  n.setAttribute("aria-hidden", "true");
  [...FACES].forEach((f, i) => {
    const c = document.createElement("i");
    c.dataset.f = f;
    c.style.background = css[i];
    n.appendChild(c);
  });
  return n;
};
// the faces in the order a visitor goes round a cube in hand
const ROUND = [
  [0, "On top"],
  [2, "Facing you"],
  [1, "On the right"],
  [5, "At the back"],
  [4, "On the left"],
  [3, "Underneath"],
];
const draw = () => {
  const s = S;
  const list = document.getElementById("sch-list");
  list.replaceChildren(
    ...[...Array(s["sc.count"]())].map((_, i) => {
      const k = String(i);
      const b = document.createElement("button");
      b.type = "button";
      b.className = "sch-opt";
      b.setAttribute("role", "radio");
      b.setAttribute("aria-checked", String(cur.key === k));
      const t = document.createElement("span");
      t.className = "sch-opt-t";
      const nm = document.createElement("b");
      nm.textContent = s["sc.name.of"](k);
      const ab = document.createElement("span");
      ab.textContent = s["sc.about.of"](k);
      t.append(nm, ab);
      b.append(net(s["sc.css.of"](k).split(" ")), t);
      b.dataset.k = k;
      b.addEventListener("click", async () => {
        await use(k);
        draw();
        list.querySelector(`[data-k="${k}"]`)?.focus();
      });
      return b;
    }),
  );
  const own = cur.key.length === 6;
  document.getElementById("sch-own").open ||= own;
  const names = s["sc.palette"]().split(" ");
  const shades = s["sc.palette.css"]().split(" ");
  const faces = [...s["sc.faces.of"](cur.key)].map(Number);
  document.getElementById("sch-faces").replaceChildren(
    ...ROUND.map(([f, where]) => {
      const row = document.createElement("div");
      row.className = "sch-face";
      row.setAttribute("role", "radiogroup");
      row.setAttribute("aria-label", `${where}: the ${FACES[f]} face's color`);
      const l = document.createElement("span");
      l.className = "sch-where";
      l.innerHTML = `<b>${FACES[f]}</b> ${where}`;
      row.appendChild(l);
      names.forEach((n, c) => {
        const b = document.createElement("button");
        b.type = "button";
        b.className = "sch-sw";
        b.setAttribute("role", "radio");
        b.setAttribute("aria-label", n);
        b.title = n;
        b.setAttribute("aria-checked", String(faces[f] === c));
        b.style.setProperty("--c", shades[c]);
        b.dataset.f = String(f);
        b.dataset.c = String(c);
        b.addEventListener("click", async () => {
          await use(s["sc.pick"](cur.key, f, c));
          draw();
          document.querySelector(`#sch-faces [data-f="${f}"][data-c="${c}"]`)?.focus();
        });
        row.appendChild(b);
      });
      return row;
    }),
  );
  document.getElementById("sch-now").textContent = cur.name;
};
const open = async () => {
  await bend();
  draw();
  dlg().showModal();
};

export const colors = {
  // the scheme now: key, name, names (U R F D L B)
  now: () => cur,
  name,
  // a message in the scheme's colors (as is until Scheme.bend is loaded)
  say: (t) => (S && cur.key !== "0" ? S["sc.say"](cur.key, t) : t),
  ready: bend,
  use,
  open,
  on: (h) => hooks.push(h),
};

// the page opens in the kept scheme's shades at once; its words once
// Scheme.bend is in, and the kept scheme checked again then
paint();
for (const b of document.querySelectorAll("[data-sch-open]")) b.addEventListener("click", () => open());
if (cur.key !== "0")
  bend()
    .then(() => use(cur.key))
    .then((why) => why && use("0"))
    .catch(() => {});
// a scheme picked in another tab of the page is this one's too
addEventListener("storage", (e) => {
  if (e.key !== STORE) return;
  const k = (kept() ?? STANDARD).key;
  if (k !== cur.key)
    use(k)
      .then(() => dlg()?.open && draw())
      .catch(() => {});
});
