import { main } from "./src/typescript/cli.ts";

process.exit(await main(process.argv.slice(2)));
