// Screenshots of the page in headless Chrome, driven over the DevTools protocol:
//   node probe/shot.mjs URL WIDTHxHEIGHT STEPS...
// a step is click:SELECTOR, wait:MS, shot:FILE.png or eval:EXPRESSION. The page's
// console errors and exceptions are printed.
import { spawn } from "node:child_process";
import { writeFileSync, mkdtempSync } from "node:fs";

const [url, size, ...steps] = process.argv.slice(2);
const [width, height] = size.split("x").map(Number);
const sleep = (ms) => new Promise((ok) => setTimeout(ok, ms));
const port = 9333;
const chrome = spawn(
  process.env.CHROME || "google-chrome-stable",
  [
    "--headless=new",
    `--remote-debugging-port=${port}`,
    `--user-data-dir=${mkdtempSync("/tmp/cube-chrome-")}`,
    `--window-size=${width},${height}`,
    "--use-angle=swiftshader",
    "--enable-unsafe-swiftshader",
    "--no-first-run",
    "--no-default-browser-check",
    "--hide-scrollbars",
    "about:blank",
  ],
  { stdio: "ignore" },
);
try {
  let page;
  for (let i = 0; i < 160 && !page; i++) {
    await sleep(250);
    try {
      page = (await (await fetch(`http://127.0.0.1:${port}/json`)).json()).find((t) => t.type === "page");
    } catch {}
  }
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  let id = 0;
  const waiting = new Map();
  ws.onmessage = (m) => {
    const d = JSON.parse(m.data);
    if (d.id && waiting.has(d.id)) {
      waiting.get(d.id)(d);
      waiting.delete(d.id);
    } else if (d.method === "Runtime.exceptionThrown") {
      console.log("EXCEPTION", JSON.stringify(d.params.exceptionDetails).slice(0, 600));
    } else if (d.method === "Runtime.consoleAPICalled" && ["error", "warning"].includes(d.params.type)) {
      console.log("CONSOLE", d.params.type, d.params.args.map((a) => a.value ?? a.description).join(" ").slice(0, 400));
    } else if (d.method === "Log.entryAdded" && d.params.entry.level === "error") {
      console.log("LOG", d.params.entry.text.slice(0, 300), d.params.entry.url ?? "");
    }
  };
  await new Promise((ok) => (ws.onopen = ok));
  const send = (method, params = {}) =>
    new Promise((ok) => {
      const i = ++id;
      waiting.set(i, ok);
      ws.send(JSON.stringify({ id: i, method, params }));
    });
  await send("Page.enable");
  await send("Runtime.enable");
  await send("Log.enable");
  await send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: 1, mobile: width < 700 });
  await send("Page.navigate", { url });
  await sleep(2500);
  for (const s of steps) {
    const [k, ...rest] = s.split(":");
    const v = rest.join(":");
    if (k === "wait") await sleep(Number(v));
    else if (k === "click") await send("Runtime.evaluate", { expression: `document.querySelector(${JSON.stringify(v)})?.click()` });
    else if (k === "eval") {
      const r = await send("Runtime.evaluate", { expression: v, returnByValue: true });
      console.log("EVAL", JSON.stringify(r.result?.result?.value ?? r.result).slice(0, 1500));
    } else if (k === "shot") {
      const r = await send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
      writeFileSync(v, Buffer.from(r.result.data, "base64"));
      console.log("SHOT", v);
    }
  }
  ws.close();
} finally {
  chrome.kill();
}
