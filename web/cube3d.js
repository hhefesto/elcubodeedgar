// The cube in 3D (three.js). It keeps no cube of its own: App.bend hands it
// the 54 stickers to paint (paint), or a move to animate and the stickers the
// cube has after it (turn). A turn swings the layer's cubies about the move's
// axis, then puts every cubie back where it started and paints the stickers
// it was handed: probe/turns.mjs checks that the swing and Cube.bend agree, so
// the repaint shows what the swing ended on.
import * as THREE from "./three.module.min.js";
import { sticker, turn } from "./geom.js";

const COLOR = { U: 0xf4f0e6, R: 0xc41230, F: 0x00a04e, D: 0xffd31a, L: 0xff6a13, B: 0x0b4fb3 };
const AXIS = ["x", "y", "z"];

// a rounded square in the xy plane, side a, corner radius r
function rounded(a, r) {
  const h = a / 2;
  const s = new THREE.Shape();
  s.moveTo(-h + r, -h);
  s.lineTo(h - r, -h);
  s.quadraticCurveTo(h, -h, h, -h + r);
  s.lineTo(h, h - r);
  s.quadraticCurveTo(h, h, h - r, h);
  s.lineTo(-h + r, h);
  s.quadraticCurveTo(-h, h, -h, h - r);
  s.lineTo(-h, -h + r);
  s.quadraticCurveTo(-h, -h, -h + r, -h);
  return s;
}

// a cubie's body: a rounded square pushed out, its edges bevelled
function bodyGeometry() {
  const bevel = 0.07;
  const g = new THREE.ExtrudeGeometry(rounded(0.95 - 2 * bevel, 0.1), {
    depth: 0.95 - 2 * bevel,
    bevelEnabled: true,
    bevelThickness: bevel,
    bevelSize: bevel,
    bevelSegments: 4,
    curveSegments: 6,
  });
  g.translate(0, 0, -(0.95 - 2 * bevel) / 2);
  g.computeVertexNormals();
  return g;
}

// the soft shadow under the cube
function shadowTexture() {
  const c = document.createElement("canvas");
  c.width = c.height = 256;
  const x = c.getContext("2d");
  const g = x.createRadialGradient(128, 128, 8, 128, 128, 128);
  g.addColorStop(0, "rgba(40, 28, 16, 0.42)");
  g.addColorStop(0.45, "rgba(40, 28, 16, 0.16)");
  g.addColorStop(1, "rgba(40, 28, 16, 0)");
  x.fillStyle = g;
  x.fillRect(0, 0, 256, 256);
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  return t;
}

const easeInOut = (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);
// a little past, then back: a turn that lands
const easeBack = (t) => {
  const c = 1.15;
  return 1 + (c + 1) * Math.pow(t - 1, 3) + c * Math.pow(t - 1, 2);
};

export function cube3d(el) {
  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(globalThis.devicePixelRatio || 1, 2));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.05;
  el.appendChild(renderer.domElement);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(28, 1, 0.1, 100);
  const home = new THREE.Vector3(6.0, 4.9, 7.4);

  scene.add(new THREE.HemisphereLight(0xfff4e2, 0x6b5a48, 1.5));
  const key = new THREE.DirectionalLight(0xffffff, 2.4);
  key.position.set(4, 9, 6);
  scene.add(key);
  const rim = new THREE.DirectionalLight(0xffd9b0, 1.1);
  rim.position.set(-7, 2, -5);
  scene.add(rim);
  const fill = new THREE.DirectionalLight(0xdfe8ff, 0.5);
  fill.position.set(-3, -4, 6);
  scene.add(fill);

  const shadow = new THREE.Mesh(
    new THREE.PlaneGeometry(5.6, 5.6),
    new THREE.MeshBasicMaterial({ map: shadowTexture(), transparent: true, depthWrite: false }),
  );
  shadow.rotation.x = -Math.PI / 2;
  shadow.position.y = -2.05;
  scene.add(shadow);

  // tilt (the trackball's turn, below) holds spin (a slight sway) holds the
  // cubies
  const tilt = new THREE.Group();
  const spin = new THREE.Group();
  tilt.add(spin);
  scene.add(tilt);
  const start = tilt.quaternion.clone();

  const bodyGeo = bodyGeometry();
  const bodyMat = new THREE.MeshStandardMaterial({ color: 0x15120f, roughness: 0.42, metalness: 0.0 });
  const stickerGeo = new THREE.ShapeGeometry(rounded(0.8, 0.13), 6);
  const mats = {};
  for (const f in COLOR) {
    mats[f] = new THREE.MeshPhysicalMaterial({
      color: COLOR[f],
      roughness: 0.3,
      metalness: 0.0,
      clearcoat: 0.6,
      clearcoatRoughness: 0.25,
    });
  }

  const cubies = new Map();
  for (let x = -1; x <= 1; x++)
    for (let y = -1; y <= 1; y++)
      for (let z = -1; z <= 1; z++) {
        if (x === 0 && y === 0 && z === 0) continue;
        const g = new THREE.Group();
        g.position.set(x, y, z);
        g.userData.home = [x, y, z];
        g.add(new THREE.Mesh(bodyGeo, bodyMat));
        spin.add(g);
        cubies.set(`${x},${y},${z}`, g);
      }

  const z = new THREE.Vector3(0, 0, 1);
  const stickers = [];
  for (let i = 0; i < 54; i++) {
    const { p, n } = sticker(i);
    const m = new THREE.Mesh(stickerGeo, mats.U);
    const nv = new THREE.Vector3(...n);
    m.quaternion.setFromUnitVectors(z, nv);
    m.position.copy(nv.multiplyScalar(0.478));
    cubies.get(p.join(",")).add(m);
    stickers.push(m);
  }

  const paint = (facelets) => {
    for (let i = 0; i < 54; i++) stickers[i].material = mats[facelets[i]] ?? mats.U;
  };

  // the visitor's cube's colours (web/colours.js): a CSS colour for each face,
  // U R F D L B; none, the standard ones. The faces whose colour changed are
  // kept for show() to show (quiet: none to show, as when the page opens).
  const hex = () => Object.fromEntries([..."URFDLB"].map((f) => [f, mats[f].color.getHexString()]));
  let seen = hex();
  const colours = (css, quiet) => {
    [..."URFDLB"].forEach((f, i) => mats[f].color.set(css?.[i] ?? COLOR[f]));
    const now = hex();
    el.dataset.colours = [..."URFDLB"].map((f) => "#" + now[f]).join(" ");
    if (quiet) seen = now;
  };

  // A change of colours, shown: a cube in Japanese colours is the standard
  // one with blue and yellow swapped, underneath and at the back, where the
  // cube hides them; so the cube turns to show the faces that changed, holds
  // a moment, and goes back to where it was. Of its 24 ways to stand, the one
  // that shows the most of them, the nearest; no turn if it shows as many now
  // (Mirrored: red is on the right, in view).
  const NORMAL = { U: [0, 1, 0], R: [1, 0, 0], F: [0, 0, 1], D: [0, -1, 0], L: [-1, 0, 0], B: [0, 0, -1] };
  const stands = [];
  for (const y of Object.values(NORMAL))
    for (const z of Object.values(NORMAL)) {
      if (y.some((a, i) => a !== 0 && z[i] !== 0)) continue;
      const Y = new THREE.Vector3(...y);
      const Z = new THREE.Vector3(...z);
      const X = new THREE.Vector3().crossVectors(Y, Z);
      stands.push(start.clone().multiply(new THREE.Quaternion().setFromRotationMatrix(new THREE.Matrix4().makeBasis(X, Y, Z))));
    }
  let look = null;
  const nv = new THREE.Vector3();
  const show = () => {
    const now = hex();
    const faces = [..."URFDLB"].filter((f) => now[f] !== seen[f]);
    seen = now;
    if (!faces.length) return "";
    el.dataset.look = faces.join("");
    // in view: facing the camera well, not edge on
    const eye = camera.position.clone().normalize();
    const shown = (q) => faces.filter((f) => nv.set(...NORMAL[f]).applyQuaternion(q).dot(eye) > 0.3).length;
    const back = (look ? look.back : tilt.quaternion).clone();
    let to = back;
    let most = shown(back);
    let near = Infinity;
    for (const q of stands) {
      const n = shown(q);
      const a = q.angleTo(back);
      if (n > most || (n === most && to !== back && a < near)) [to, most, near] = [q, n, a];
    }
    el.dataset.lookTurn = String(to !== back);
    if (to === back) return el.dataset.look;
    view.w = 0;
    view.back = false;
    look = { at: tilt.quaternion.clone(), to, back, t0: performance.now() };
    return el.dataset.look;
  };
  const GO = 700;
  const HOLD = 1600;
  const looking = (now) => {
    const t = now - look.t0;
    if (view.drag || view.back) look = null;
    else if (t < GO) tilt.quaternion.slerpQuaternions(look.at, look.to, easeInOut(t / GO));
    else if (t < GO + HOLD) tilt.quaternion.copy(look.to);
    else if (t < 2 * GO + HOLD) tilt.quaternion.slerpQuaternions(look.to, look.back, easeInOut((t - GO - HOLD) / GO));
    else {
      tilt.quaternion.copy(look.back);
      look = null;
    }
  };

  // Turns
  let anim = null;

  const settle = () => {
    for (const c of [...anim.pivot.children]) {
      spin.attach(c);
      c.position.set(...c.userData.home);
      c.quaternion.identity();
    }
    spin.remove(anim.pivot);
    paint(anim.after);
    const done = anim.done;
    anim = null;
    done("");
  };

  const turnMove = (name, ms, after, done) => {
    if (anim) settle();
    const { axis, layer, angle } = turn(name);
    const pivot = new THREE.Group();
    spin.add(pivot);
    for (const c of cubies.values()) if (c.userData.home[axis] === layer) pivot.attach(c);
    anim = { pivot, axis, angle, after, done, t0: performance.now(), ms: Math.max(ms, 1), ease: ms > 300 ? easeBack : easeInOut };
  };

  // Looking around: a trackball. A drag turns the cube about the axis at
  // right angles to it, as the camera sees it, by the drag's length: every
  // face can be brought to the front, from any side, with no pole to stop at
  // (a quaternion, three.js's: no gimbal lock). A flick goes on and slows; a
  // double click or double tap brings the cube back to how it started.
  const view = { drag: null, axis: new THREE.Vector3(0, 1, 0), w: 0, t: 0, back: false };
  const K = 0.0085;
  const dq = new THREE.Quaternion();
  const ax = new THREE.Vector3();
  const turnView = (axis, angle) => {
    dq.setFromAxisAngle(axis, angle);
    tilt.quaternion.premultiply(dq).normalize();
  };
  el.addEventListener("pointerdown", (e) => {
    view.drag = { x: e.clientX, y: e.clientY, id: e.pointerId };
    view.w = 0;
    view.back = false;
    try {
      el.setPointerCapture(e.pointerId);
    } catch {}
    el.classList.add("dragging");
  });
  el.addEventListener("pointermove", (e) => {
    if (!view.drag || e.pointerId !== view.drag.id) return;
    const dx = e.clientX - view.drag.x;
    const dy = e.clientY - view.drag.y;
    view.drag.x = e.clientX;
    view.drag.y = e.clientY;
    view.t = performance.now();
    const len = Math.hypot(dx, dy);
    if (len === 0) return;
    // (dy, dx, 0) in the camera's frame: right turns about its up, down
    // about its right; in the world's
    ax.set(dy / len, dx / len, 0).applyQuaternion(camera.quaternion).normalize();
    view.axis.copy(ax);
    view.w = len * K;
    turnView(ax, view.w);
  });
  const up = (e) => {
    if (view.drag && e && e.pointerId !== view.drag.id) return;
    // held still before letting go: no flick
    if (performance.now() - (view.t || 0) > 80) view.w = 0;
    view.drag = null;
    el.classList.remove("dragging");
  };
  el.addEventListener("pointerup", up);
  el.addEventListener("pointercancel", up);
  el.addEventListener("dblclick", () => {
    view.w = 0;
    view.back = true;
  });

  const fit = () => {
    const w = el.clientWidth || 1;
    const h = el.clientHeight || 1;
    renderer.setSize(w, h, false);
    camera.aspect = w / h;
    camera.position.copy(home).multiplyScalar(w < h ? Math.pow(h / w, 0.85) : 1);
    camera.lookAt(0, -0.35, 0);
    camera.updateProjectionMatrix();
  };
  new ResizeObserver(fit).observe(el);
  fit();

  const frame = (now) => {
    if (look) looking(now);
    if (!view.drag && view.w > 1e-4) {
      view.w *= 0.92;
      turnView(view.axis, view.w);
    }
    if (view.back) {
      tilt.quaternion.slerp(start, 0.15);
      if (tilt.quaternion.angleTo(start) < 1e-3) {
        tilt.quaternion.copy(start);
        view.back = false;
      }
    }
    spin.rotation.y = Math.sin(now / 2600) * 0.025;
    if (anim) {
      const t = Math.min(1, (now - anim.t0) / anim.ms);
      anim.pivot.rotation[AXIS[anim.axis]] = anim.angle * anim.ease(t);
      if (t >= 1) settle();
    }
    renderer.render(scene, camera);
    requestAnimationFrame(frame);
  };
  requestAnimationFrame(frame);

  // a turn never waits on a hidden tab: its frames stop, so end it at once
  document.addEventListener("visibilitychange", () => {
    if (document.hidden && anim) settle();
  });

  return { paint, turn: turnMove, colours, show };
}
