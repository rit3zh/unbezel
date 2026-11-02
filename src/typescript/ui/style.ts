type RGB = readonly [number, number, number];
type Paint = (text: string) => string;

const env = process.env;
const color =
  env.FORCE_COLOR !== undefined ||
  (Boolean(process.stdout.isTTY) &&
    env.NO_COLOR === undefined &&
    env.TERM !== "dumb");
const truecolor =
  color &&
  (/truecolor|24bit/i.test(env.COLORTERM ?? "") ||
    ["iTerm.app", "vscode", "WezTerm", "ghostty"].includes(
      env.TERM_PROGRAM ?? "",
    ));
const ansi = /\x1b\[[0-9;]*m/g;

function sgr(open: number, close: number): Paint {
  return (text) => (color ? `\x1b[${open}m${text}\x1b[${close}m` : text);
}

const style = {
  bold: sgr(1, 22),
  dim: sgr(2, 22),
  red: sgr(31, 39),
  green: sgr(32, 39),
  yellow: sgr(33, 39),
  cyan: sgr(36, 39),
  gray: sgr(90, 39),
};

function cube(value: number): number {
  return Math.round((value / 255) * 5);
}

function rgb([r, g, b]: RGB): Paint {
  if (!color) return (text) => text;
  const code = truecolor
    ? `38;2;${r};${g};${b}`
    : `38;5;${16 + 36 * cube(r) + 6 * cube(g) + cube(b)}`;
  return (text) => `\x1b[${code}m${text}\x1b[39m`;
}

function mix(from: RGB, to: RGB, t: number): RGB {
  return [0, 1, 2].map((i) =>
    Math.round(from[i]! + (to[i]! - from[i]!) * t),
  ) as unknown as RGB;
}

function gradient(text: string, from: RGB, to: RGB): string {
  const chars = [...text];
  return chars
    .map((char, i) => rgb(mix(from, to, i / (chars.length - 1 || 1)))(char))
    .join("");
}

function visibleLength(text: string): number {
  return [...text.replace(ansi, "")].length;
}

function truncate(text: string, max: number): string {
  let visible = 0;
  let out = "";
  for (const part of text.split(/(\x1b\[[0-9;]*m)/)) {
    if (part.startsWith("\x1b[")) {
      out += part;
      continue;
    }
    for (const char of part) {
      if (visible >= max) return out + (color ? "\x1b[0m" : "");
      out += char;
      visible += 1;
    }
  }
  return out;
}

export { style, rgb, mix, gradient, visibleLength, truncate };
export type { RGB, Paint };
