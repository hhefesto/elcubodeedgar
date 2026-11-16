// The cube's geometry, shared by the 3D view (cube3d.js) and its test
// (probe/turns.mjs): no three.js here, only numbers.
//
// Coordinates: x right, y up, z toward the viewer (the F face). A cubie sits at
// (x, y, z), each -1, 0 or 1; a sticker is a cubie and a face's outward normal.

// The 54 stickers in Kociemba's facelet order, U1..U9 R1..R9 F1..F9 D1..D9
// L1..L9 B1..B9, each face read row by row as seen from outside with U (or,
// for U and D, B and F) at the top: what Cube.bend's cube.facelets writes.
export const FACES = "URFDLB";

export function sticker(i) {
  const f = FACES[Math.floor(i / 9)];
  const k = i % 9;
  const r = Math.floor(k / 3);
  const c = k % 3;
  switch (f) {
    case "U": return { p: [c - 1, 1, r - 1], n: [0, 1, 0] };
    case "R": return { p: [1, 1 - r, 1 - c], n: [1, 0, 0] };
    case "F": return { p: [c - 1, 1 - r, 1], n: [0, 0, 1] };
    case "D": return { p: [c - 1, -1, 1 - r], n: [0, -1, 0] };
    case "L": return { p: [-1, 1 - r, c - 1], n: [-1, 0, 0] };
    default: return { p: [1 - c, 1 - r, -1], n: [0, 0, -1] };
  }
}

// A move ("R", "U2", "F'"): the axis it turns about (0 x, 1 y, 2 z), the layer
// it turns (the cubies with that coordinate, 1 or -1), and the angle about the
// axis. Clockwise as seen from outside the face is a negative turn about its
// outward normal (layer times the axis).
const AXES = { U: [1, 1], D: [1, -1], R: [0, 1], L: [0, -1], F: [2, 1], B: [2, -1] };

export function turn(name) {
  const [axis, layer] = AXES[name[0]];
  const s = name.slice(1);
  const q = s === "2" ? 2 : s === "'" ? -1 : 1;
  return { axis, layer, angle: (-layer * q * Math.PI) / 2 };
}

// a point turned about an axis by a multiple of a quarter turn
export function rot([x, y, z], axis, a) {
  const c = Math.round(Math.cos(a));
  const s = Math.round(Math.sin(a));
  if (axis === 0) return [x, y * c - z * s, y * s + z * c];
  if (axis === 1) return [x * c + z * s, y, -x * s + z * c];
  return [x * c - y * s, x * s + y * c, z];
}

const key = (p, n) => p.join(",") + "/" + n.join(",");
const INDEX = new Map(Array.from({ length: 54 }, (_, i) => [key(sticker(i).p, sticker(i).n), i]));

// the stickers after a move, moving each sticker of the layer as the 3D view
// moves it: what the view shows once the turn ends
export function turned(facelets, name) {
  const { axis, layer, angle } = turn(name);
  const out = facelets.split("");
  for (let i = 0; i < 54; i++) {
    const { p, n } = sticker(i);
    if (p[axis] !== layer) continue;
    out[INDEX.get(key(rot(p, axis, angle), rot(n, axis, angle)))] = facelets[i];
  }
  return out.join("");
}
