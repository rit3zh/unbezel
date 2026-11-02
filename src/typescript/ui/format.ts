import { homedir } from "node:os";

function formatBytes<T extends number>(bytes: T): string {
  const units = ["B", "KB", "MB", "GB"];
  let value = bytes as number;
  let unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit += 1;
  }
  return `${value.toFixed(unit === 0 ? 0 : 1)} ${units[unit]}`;
}

function formatDuration<T extends number>(seconds: T): string {
  if (seconds < 60) return `${seconds.toFixed(1)}s`;
  const minutes = Math.floor(seconds / 60);
  return `${minutes}m ${String(Math.round(seconds % 60)).padStart(2, "0")}s`;
}

function formatPath(path: string, max = Infinity): string {
  const home = homedir();
  const short = path.startsWith(home) ? `~${path.slice(home.length)}` : path;
  if (short.length <= max) return short;
  return `…${short.slice(short.length - max + 1)}`;
}

function wrap<T extends string>(text: T, width: number): string[] {
  return text.split("\n").flatMap((paragraph) => {
    const lines: string[] = [];
    let line = "";
    const words = paragraph
      .split(" ")
      .flatMap((word) => word.match(new RegExp(`.{1,${width}}`, "g")) ?? [""]);
    for (const word of words) {
      if (line && line.length + word.length + 1 > width) {
        lines.push(line);
        line = word;
      } else {
        line = line ? `${line} ${word}` : word;
      }
    }
    return [...lines, line];
  });
}

export { formatBytes, formatDuration, formatPath, wrap };
