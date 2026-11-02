import { basename } from "node:path";
import type { DetectedEvent, Rect, StartEvent } from "../events.ts";
import { formatBytes, formatDuration, formatPath, wrap } from "./format.ts";
import {
  gradient,
  mix,
  rgb,
  style,
  visibleLength,
  type Paint,
  type RGB,
} from "./style.ts";

const indent = "  ";
const violet: RGB = [167, 139, 250];
const cyan: RGB = [34, 211, 238];

function columns(): number {
  return process.stdout.columns || 80;
}

function size({ w, h }: Rect): string {
  return `${w}×${h}`;
}

function header(): string[] {
  return [
    "",
    `${indent}${style.bold(gradient("◆ unbezel", violet, cyan))}  ${style.dim("strip device frames from simulator recordings")}`,
    "",
  ];
}

function elapsed(ms?: number): string {
  return ms === undefined ? "" : style.dim(` · ${formatDuration(ms / 1000)}`);
}

function done(label: string, ms?: number): string {
  return `${indent}${style.green("✔")} ${label}${elapsed(ms)}`;
}

function failed<T extends string>(label: T): string {
  return `${indent}${style.red("✖")} ${label}`;
}

function pending(spinner: string, label: string): string {
  return `${indent}${style.cyan(spinner)} ${label}${style.dim("…")}`;
}

function detail(key: string, value: string): string {
  return `${indent}  ${style.gray("│")} ${style.gray(key.padEnd(9))}${value}`;
}

function bar(fraction: number, width: number): string {
  const filled = Math.round(Math.min(Math.max(fraction, 0), 1) * width);
  let out = "";
  for (let i = 0; i < filled; i++) {
    out += rgb(mix(violet, cyan, i / (width - 1 || 1)))("━");
  }
  return out + style.gray("─".repeat(width - filled));
}

function progress(
  spinner: string,
  label: string,
  fraction: number,
  extra: string,
): string {
  const width = Math.max(10, Math.min(32, columns() - 64));
  const percent = `${Math.floor(Math.min(fraction, 1) * 100)}%`.padStart(4);
  return `${indent}${style.cyan(spinner)} ${label.padEnd(10)} ${bar(fraction, width)} ${style.bold(percent)}  ${style.dim(extra)}`;
}

function eta(fraction: number, ms: number): string {
  if (fraction < 0.03 || fraction >= 1) return "";
  return `eta ${formatDuration(((ms / fraction) * (1 - fraction)) / 1000)}`;
}

function source(start: StartEvent): string[] {
  const parts = [
    `${start.width}×${start.height}`,
    formatDuration(start.duration),
    `${Math.round(start.fps)} fps`,
    start.audio ? "audio" : "no audio",
  ];
  return [detail("source", parts.join(style.dim(" · ")))];
}

function frame(info: DetectedEvent): string[] {
  const island = info.island
    ? `${size(info.island)} ${style.dim("·")} ${info.keepIsland ? style.yellow("kept") : style.green("removed")}`
    : style.dim("none found");
  return [
    detail(
      "screen",
      `${size(info.screen)} ${style.dim(`at ${info.screen.x}, ${info.screen.y}`)}`,
    ),
    detail("corners", `≈${info.radius}px radius`),
    detail("island", island),
  ];
}

function box(lines: string[], border: Paint): string[] {
  const inner = Math.max(...lines.map(visibleLength));
  const pad = (line: string) => line + " ".repeat(inner - visibleLength(line));
  return [
    `${indent}${border(`╭${"─".repeat(inner + 4)}╮`)}`,
    ...lines.map(
      (line) => `${indent}${border("│")}  ${pad(line)}  ${border("│")}`,
    ),
    `${indent}${border(`╰${"─".repeat(inner + 4)}╯`)}`,
  ];
}

function row(key: string, value: string): string {
  return `${style.gray(key.padEnd(9))}${value}`;
}

type Summary = {
  output: string;
  bytes: number;
  screen: Rect;
  frames: number;
  duration: number;
  ms: number;
};

function summary(result: Summary): string[] {
  const seconds = result.ms / 1000;
  const speed =
    result.duration > 0
      ? `${(result.duration / seconds).toFixed(1)}× realtime`
      : "";
  return box(
    [
      `${style.green("✔")} ${style.bold("Saved")} ${style.dim(`in ${formatDuration(seconds)}`)}`,
      "",
      row("output", style.bold(formatPath(result.output, columns() - 24))),
      row(
        "size",
        `${formatBytes(result.bytes)} ${style.dim("·")} ${size(result.screen)}`,
      ),
      row(
        "video",
        `${result.frames} frames ${style.dim("·")} ${formatDuration(result.duration)}`,
      ),
      ...(speed ? [row("speed", speed)] : []),
    ],
    style.green,
  );
}

function errorBox(title: string, message: string): string[] {
  const width = Math.max(30, Math.min(72, columns() - 12));
  return box(
    [
      `${style.red("✖")} ${style.bold(title)}`,
      "",
      ...wrap(message, width).map(style.dim),
    ],
    style.red,
  );
}

function help(): string[] {
  const command = (text: string) => style.cyan(text);
  const heading = (text: string) => style.bold(text);
  return [
    `${indent}${heading("USAGE")}`,
    `${indent}  ${command("bun run unbezel")} <input> ${style.dim("[output] [options]")}`,
    "",
    `${indent}${heading("ARGUMENTS")}`,
    `${indent}  ${"input".padEnd(16)}${style.dim("screen recording with a device frame")}`,
    `${indent}  ${"output".padEnd(16)}${style.dim("where to save the result (default: next to input)")}`,
    "",
    `${indent}${heading("OPTIONS")}`,
    `${indent}  ${"--keep-island".padEnd(16)}${style.dim("leave the Dynamic Island in place")}`,
    `${indent}  ${"-h, --help".padEnd(16)}${style.dim("show this help")}`,
    "",
    `${indent}${heading("EXAMPLES")}`,
    `${indent}  ${command("bun run unbezel")} demo-with-frame.mp4      ${style.dim("→ demo.mp4")}`,
    `${indent}  ${command("bun run unbezel")} clip.mov out.mp4 --keep-island`,
    "",
  ];
}

function inputName(start: StartEvent): string {
  return style.bold(basename(start.input));
}

export {
  header,
  done,
  failed,
  pending,
  progress,
  eta,
  source,
  frame,
  summary,
  errorBox,
  help,
  inputName,
};
