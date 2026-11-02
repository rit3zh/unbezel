import { truncate } from "./style.ts";

const spinnerFrames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

class Terminal {
  readonly interactive = Boolean(process.stdout.isTTY);
  private render: () => string[] = () => [];
  private drawn = 0;
  private tick = 0;
  private timer: ReturnType<typeof setInterval> | undefined;

  constructor() {
    if (this.interactive) {
      process.on("exit", () => process.stdout.write("\x1b[?25h"));
    }
  }

  get spinner(): string {
    return spinnerFrames[this.tick % spinnerFrames.length]!;
  }

  get columns(): number {
    return process.stdout.columns || 80;
  }

  live(render: () => string[]): void {
    this.render = render;
    if (!this.interactive) return;
    if (!this.timer) {
      process.stdout.write("\x1b[?25l");
      this.timer = setInterval(() => {
        this.tick += 1;
        this.draw();
      }, 80);
    }
    this.draw();
  }

  print(...lines: string[]): void {
    process.stdout.write(this.erase() + lines.map((line) => `${line}\n`).join(""));
    this.draw();
  }

  stop(): void {
    process.stdout.write(this.erase());
    clearInterval(this.timer);
    this.timer = undefined;
    this.render = () => [];
    if (this.interactive) process.stdout.write("\x1b[?25h");
  }

  private draw(): void {
    if (!this.timer) return;
    const lines = this.render().map((line) => truncate(line, this.columns - 1));
    process.stdout.write(this.erase() + lines.map((line) => `${line}\n`).join(""));
    this.drawn = lines.length;
  }

  private erase(): string {
    const sequence = this.drawn > 0 ? `\x1b[${this.drawn}F\x1b[J` : "";
    this.drawn = 0;
    return sequence;
  }
}

export { Terminal };
