import { unlink } from "node:fs/promises";
import { paths } from "./paths.ts";
import {
  readEvents,
  type DetectedEvent,
  type SavedEvent,
  type StartEvent,
} from "./events.ts";
import type { Terminal } from "./ui/terminal.ts";
import * as view from "./ui/view.ts";

async function runBinary(args: string[], terminal: Terminal): Promise<number> {
  const proc = Bun.spawn([paths.binary, ...args], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const stderr = new Response(proc.stderr).text();
  const startedAt = performance.now();
  let phaseAt = startedAt;
  let start: StartEvent | undefined;
  let detected: DetectedEvent | undefined;
  let saved: SavedEvent | undefined;
  let error: string | undefined;
  let analyzed = 0;
  let exported = 0;

  process.once("SIGINT", async () => {
    proc.kill();
    terminal.stop();
    terminal.print(view.failed("Cancelled"), "");
    if (start && !saved) await unlink(start.output).catch(() => {});
    process.exit(130);
  });

  terminal.live(() => {
    const ms = performance.now() - phaseAt;
    if (!start) return [view.pending(terminal.spinner, "Opening video")];
    if (!detected) {
      return [view.progress(terminal.spinner, "Analyzing", analyzed, view.eta(analyzed, ms))];
    }
    const fraction = detected.frames > 0 ? exported / detected.frames : 0;
    const fps = ms > 0 ? Math.round(exported / (ms / 1000)) : 0;
    const extra = [`${exported}/${detected.frames}`, `${fps} fps`, view.eta(fraction, ms)];
    return [view.progress(terminal.spinner, "Exporting", fraction, extra.filter(Boolean).join(" · "))];
  });

  for await (const event of readEvents(proc.stdout)) {
    switch (event.event) {
      case "start":
        start = event;
        phaseAt = performance.now();
        break;
      case "analyze":
        analyzed = event.progress;
        break;
      case "detected":
        detected = event;
        terminal.print(
          view.done(`Analyzed ${start ? view.inputName(start) : "video"}`, performance.now() - phaseAt),
          ...(start ? view.source(start) : []),
          view.done("Detected device frame"),
          ...view.frame(event),
        );
        phaseAt = performance.now();
        break;
      case "export":
        exported = event.frames;
        break;
      case "saved":
        saved = event;
        terminal.print(view.done(`Exported ${event.frames} frames`, performance.now() - phaseAt));
        break;
      case "error":
        error = event.message;
        break;
    }
  }

  const exitCode = await proc.exited;
  terminal.stop();

  if (saved && detected && exitCode === 0) {
    terminal.print(
      "",
      ...view.summary({
        output: saved.output,
        bytes: Bun.file(saved.output).size,
        screen: detected.screen,
        frames: saved.frames,
        duration: start?.duration ?? 0,
        ms: performance.now() - startedAt,
      }),
      "",
    );
    return 0;
  }

  const step = !start ? "Opening video" : !detected ? "Analyzing" : "Exporting";
  const message = error ?? ((await stderr).trim() || `The engine exited with code ${exitCode}`);
  terminal.print(view.failed(`${step} failed`), "", ...view.errorBox("Something went wrong", message), "");
  return exitCode || 1;
}

export { runBinary };
