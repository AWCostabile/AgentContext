/**
 * The routes the tills and the stock screen call.
 */
import type { IncomingMessage, ServerResponse } from "node:http";
import { Ledger } from "../stock/ledger";

const ledger = new Ledger();

/** Answers one request: the counts of a title, or a delivered sale. */
export function route(req: IncomingMessage, res: ServerResponse): void {
  const url = new URL(req.url ?? "/", "http://localhost");
  if (req.method === "GET" && url.pathname.startsWith("/stock/")) {
    const key = url.pathname.slice("/stock/".length);
    reply(res, 200, { key, onHand: ledger.onHand(key) });
    return;
  }
  reply(res, 404, { error: "no such route" });
}

function reply(res: ServerResponse, status: number, body: unknown): void {
  res.writeHead(status, { "content-type": "application/json" });
  res.end(JSON.stringify(body));
}
