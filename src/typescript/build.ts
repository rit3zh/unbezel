import { mkdir, readdir, stat } from "node:fs/promises";
import { join } from "node:path";
import { paths } from "./paths.ts";

async function modifiedAt<T extends string>(path: T): Promise<number> {
  return (await stat(path).catch(() => null))?.mtimeMs ?? 0;
}

async function swiftSources(): Promise<string[]> {
  const files = await readdir(paths.swiftSources);
  return files
    .filter((file) => file.endsWith(".swift"))
    .map((file) => join(paths.swiftSources, file));
}

async function needsBuild(): Promise<boolean> {
  const sources = await swiftSources();
  const newestSource = Math.max(
    ...(await Promise.all(sources.map(modifiedAt<string>))),
  );
  return (await modifiedAt(paths.binary)) < newestSource;
}

async function build(): Promise<void> {
  await mkdir(paths.cache, { recursive: true });
  const sources = await swiftSources();
  let proc;
  try {
    proc = Bun.spawn(
      ["swiftc", "-O", "-swift-version", "5", ...sources, "-o", paths.binary],
      { stdout: "ignore", stderr: "pipe" },
    );
  } catch {
    throw new Error(
      "swiftc was not found. Install the Xcode Command Line Tools with: xcode-select --install",
    );
  }

  const [exitCode, stderr] = await Promise.all([
    proc.exited,
    new Response(proc.stderr).text(),
  ]);
  if (exitCode !== 0) {
    const errors = stderr
      .split("\n")
      .filter((line) => line.includes("error:"))
      .join("\n");
    throw new Error(errors || stderr.trim() || `swiftc exited with code ${exitCode}`);
  }
}

export { needsBuild, build };
