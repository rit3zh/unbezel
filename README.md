# unbezel

Removes the device bezel (frame, rounded corners, Dynamic Island) from iOS Simulator and mockup screen recordings and saves a plain rectangular video with the same frames and audio.

https://github.com/user-attachments/assets/95276cca-8ff2-409d-a760-42e65ad4a093

## Requirements

- macOS
- [Bun](https://bun.sh)
- Xcode Command Line Tools (`xcode-select --install`)

## Usage

```bash
git clone <repo-url>
cd unbezel
bun run unbezel path/to/video.mp4
```

The output is saved next to the input: `demo-with-frame.mp4` → `demo.mp4`, anything else → `name-no-frame.mp4`.

```bash
bun run unbezel <input> [output] [--keep-island]
```

- `output` — custom output path
- `--keep-island` — leave the Dynamic Island in place

The Swift code compiles automatically on the first run.
