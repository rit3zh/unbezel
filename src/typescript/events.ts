type Rect = { x: number; y: number; w: number; h: number };

type StartEvent = {
  event: "start";
  input: string;
  output: string;
  width: number;
  height: number;
  duration: number;
  fps: number;
  audio: boolean;
};

type DetectedEvent = {
  event: "detected";
  screen: Rect;
  radius: number;
  island: Rect | null;
  keepIsland: boolean;
  frames: number;
};

type SavedEvent = { event: "saved"; output: string; frames: number };

type EngineEvent =
  | StartEvent
  | DetectedEvent
  | SavedEvent
  | { event: "analyze"; progress: number }
  | { event: "export"; frames: number; total: number }
  | { event: "error"; message: string };

function parse(line: string): EngineEvent | undefined {
  if (!line.trim()) return undefined;
  try {
    return JSON.parse(line) as EngineEvent;
  } catch {
    return undefined;
  }
}

async function* readEvents(
  stream: ReadableStream<Uint8Array>,
): AsyncGenerator<EngineEvent> {
  const decoder = new TextDecoder();
  let buffer = "";
  for await (const chunk of stream) {
    buffer += decoder.decode(chunk, { stream: true });
    const lines = buffer.split("\n");
    buffer = lines.pop()!;
    for (const line of lines) {
      const event = parse(line);
      if (event) yield event;
    }
  }
  const event = parse(buffer);
  if (event) yield event;
}

export { readEvents };
export type { Rect, StartEvent, DetectedEvent, SavedEvent, EngineEvent };
