import { join } from "node:path";

const root = join(import.meta.dir, "..", "..");

const paths = {
  root,
  swiftSources: join(root, "src", "swift"),
  cache: join(root, ".cache"),
  binary: join(root, ".cache", "unbezel"),
} as const;

export { paths };
