import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const root = join(process.cwd(), "build", "godot-web");
const mime = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".svg": "image/svg+xml",
};

const server = createServer(async (request, response) => {
  try {
    const pathname = decodeURIComponent(new URL(request.url, "http://127.0.0.1").pathname);
    const relative = normalize(pathname).replace(/^([/\\\\]|\.\.(?:[/\\\\]|$))+/, "");
    const filePath = join(root, relative || "index.html");
    if (!filePath.startsWith(root)) {
      response.writeHead(403).end("Forbidden");
      return;
    }
    const info = await stat(filePath);
    if (!info.isFile()) {
      response.writeHead(404).end("Not found");
      return;
    }
    response.writeHead(200, {
      "Content-Type": mime[extname(filePath)] ?? "application/octet-stream",
      "Content-Length": info.size,
      "Cache-Control": "no-store",
      "Cross-Origin-Opener-Policy": "same-origin",
      "Cross-Origin-Embedder-Policy": "require-corp",
    });
    response.end(await readFile(filePath));
  } catch {
    response.writeHead(404).end("Not found");
  }
});

await new Promise((resolve) => server.listen(4173, "127.0.0.1", resolve));

const browser = await chromium.launch({
  headless: true,
  args: [
    "--no-sandbox",
    "--disable-dev-shm-usage",
    "--enable-webgl",
    "--use-gl=angle",
    "--use-angle=swiftshader",
    "--enable-unsafe-swiftshader",
  ],
});

const failures = [];
const results = [];
try {
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 1,
    isMobile: true,
    hasTouch: true,
  });
  const page = await context.newPage();
  page.on("pageerror", (error) => failures.push(error.message));
  page.on("requestfailed", (request) => {
    failures.push(`request failed: ${request.url()} — ${request.failure()?.errorText ?? "unknown"}`);
  });

  const wasmResponse = page.waitForResponse((response) => response.url().endsWith("/index.wasm"));
  const pckResponse = page.waitForResponse((response) => response.url().endsWith("/index.pck"));
  await page.goto("http://127.0.0.1:4173/", { waitUntil: "domcontentloaded" });
  const [wasm, pck] = await Promise.all([wasmResponse, pckResponse]);
  if (!wasm.ok() || !pck.ok()) {
    throw new Error(`Game payload response failed (WASM ${wasm.status()}, PCK ${pck.status()})`);
  }

  await page.waitForFunction(() => !document.querySelector("#status"), { timeout: 90000 });
  const boot = await page.evaluate(() => {
    const canvas = document.querySelector("#canvas");
    if (!canvas) return { ok: false, reason: "missing canvas" };
    const rect = canvas.getBoundingClientRect();
    const gl = canvas.getContext("webgl2") || canvas.getContext("webgl");
    return {
      ok: rect.width > 0 && rect.height > 0 && gl !== null,
      width: rect.width,
      height: rect.height,
      drawingBufferWidth: canvas.width,
      drawingBufferHeight: canvas.height,
      webgl: gl ? gl.getParameter(gl.VERSION) : "unavailable",
      crossOriginIsolated: window.crossOriginIsolated,
    };
  });
  if (!boot.ok) throw new Error(`Godot canvas/WebGL boot check failed: ${JSON.stringify(boot)}`);
  results.push({ check: "browser boot + WebGL canvas", ...boot });

  const storage = await page.evaluate(async () => {
    const names = typeof indexedDB.databases === "function"
      ? (await indexedDB.databases()).map((entry) => entry.name).filter(Boolean)
      : [];
    const key = "block-buddies-web-smoke";
    await new Promise((resolve, reject) => {
      const open = indexedDB.open(key, 1);
      open.onupgradeneeded = () => open.result.createObjectStore("checks");
      open.onerror = () => reject(open.error);
      open.onsuccess = () => {
        const db = open.result;
        const tx = db.transaction("checks", "readwrite");
        tx.objectStore("checks").put("persisted", "marker");
        tx.oncomplete = () => { db.close(); resolve(); };
        tx.onerror = () => reject(tx.error);
      };
    });
    const marker = await new Promise((resolve, reject) => {
      const open = indexedDB.open(key, 1);
      open.onerror = () => reject(open.error);
      open.onsuccess = () => {
        const db = open.result;
        const request = db.transaction("checks").objectStore("checks").get("marker");
        request.onsuccess = () => { const value = request.result; db.close(); resolve(value); };
        request.onerror = () => reject(request.error);
      };
    });
    return { available: true, markerRoundTrip: marker === "persisted", godotDatabases: names };
  });
  if (!storage.markerRoundTrip) throw new Error("IndexedDB persistence round-trip failed");
  results.push({ check: "browser IndexedDB persistence capability", ...storage });

  for (const viewport of [{ width: 320, height: 740 }, { width: 390, height: 844 }, { width: 1280, height: 800 }]) {
    await page.setViewportSize(viewport);
    await page.waitForTimeout(250);
    const geometry = await page.locator("#canvas").evaluate((canvas) => {
      const rect = canvas.getBoundingClientRect();
      return { width: rect.width, height: rect.height };
    });
    if (geometry.width <= 0 || geometry.height <= 0) {
      throw new Error(`Canvas failed to resize at ${viewport.width}x${viewport.height}`);
    }
    results.push({ check: "viewport resize", viewport, canvas: geometry });
  }

  await page.setViewportSize({ width: 390, height: 844 });
  const bounds = await page.locator("#canvas").boundingBox();
  if (!bounds) throw new Error("Canvas bounds unavailable for touch test");
  await page.touchscreen.tap(bounds.x + bounds.width * 0.5, bounds.y + bounds.height * 0.34);
  await page.waitForTimeout(300);
  const stillRunning = await page.evaluate(() => {
    const canvas = document.querySelector("#canvas");
    return !!canvas && canvas.width > 0 && canvas.height > 0 && !document.querySelector("#status");
  });
  if (!stillRunning) throw new Error("Game stopped after mobile touch input");
  results.push({ check: "mobile touch input", passed: true });

  if (failures.length) throw new Error(`Browser runtime errors:\\n${failures.join("\\n")}`);
  console.log(JSON.stringify({ status: "PASS", results, runtimeErrors: failures }, null, 2));
  await context.close();
} finally {
  await browser.close();
  await new Promise((resolve) => server.close(resolve));
}
