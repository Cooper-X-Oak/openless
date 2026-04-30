import { mkdir } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { build } from "esbuild";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const appRoot = resolve(scriptDir, "..");
const outDir = resolve(appRoot, ".artifacts", "tests");
const outFile = resolve(outDir, "providerSetup.test.mjs");

await mkdir(outDir, { recursive: true });
await build({
  entryPoints: [resolve(appRoot, "src", "lib", "providerSetup.test.ts")],
  outfile: outFile,
  bundle: true,
  platform: "node",
  format: "esm",
  target: "node18",
  logLevel: "silent",
});

await import(`${pathToFileURL(outFile).href}?run=${Date.now()}`);
console.log("provider setup tests passed.");
