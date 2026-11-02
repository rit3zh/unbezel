import { resolve } from "node:path";
import { build, needsBuild } from "./build.ts";
import { runBinary } from "./run.ts";
import { formatPath } from "./ui/format.ts";
import { Terminal } from "./ui/terminal.ts";
import * as view from "./ui/view.ts";

async function compile(terminal: Terminal): Promise<boolean> {
  if (!(await needsBuild())) return true;

  const startedAt = performance.now();
  terminal.live(() => [view.pending(terminal.spinner, "Compiling Swift engine")]);
  try {
    await build();
  } catch (error) {
    terminal.stop();
    terminal.print(
      view.failed("Compiling Swift engine failed"),
      "",
      ...view.errorBox("Build failed", (error as Error).message),
      "",
    );
    return false;
  }
  terminal.print(view.done("Compiled Swift engine", performance.now() - startedAt));
  return true;
}

async function main(args: string[]): Promise<number> {
  const terminal = new Terminal();
  terminal.print(...view.header());

  const input = args.find((arg) => !arg.startsWith("-"));
  if (args.includes("-h") || args.includes("--help")) {
    terminal.print(...view.help());
    return 0;
  }
  if (!input) {
    terminal.print(...view.help());
    return 1;
  }
  if (!(await Bun.file(input).exists())) {
    terminal.print(...view.errorBox("File not found", formatPath(resolve(input))), "");
    return 1;
  }

  if (!(await compile(terminal))) return 1;
  return runBinary(args, terminal);
}

export { main };
