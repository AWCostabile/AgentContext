#!/usr/bin/env node
/**
 * The shop's service: the ledger, the orders and the routes the tills call.
 */
import { createServer } from "node:http";
import { route } from "./routes";

export { route } from "./routes";

/** The port the service listens on when none is configured. */
export const DEFAULT_PORT = 7300;

/** Starts the service and returns once it listens. */
export function main(): void {
  const port = Number(process.env.TILLWRIGHT_PORT ?? DEFAULT_PORT);
  createServer(route).listen(port);
}

main();
