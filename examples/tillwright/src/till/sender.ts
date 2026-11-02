/**
 * The background sender: passes stored sales to the shop's ledger in the order they were made.
 */
import type { Sale } from "./sale";
import { TillStore } from "./store";

/** Where the sender delivers a sale. A sale the ledger has already seen is acknowledged. */
export interface LedgerClient {
  deliver(sale: Sale): Promise<boolean>;
}

/** Sends waiting sales, one at a time, until one fails. Returns how many were sent. */
export async function sendWaiting(store: TillStore, ledger: LedgerClient): Promise<number> {
  let sent = 0;
  for (const sale of store.waiting()) {
    if (!(await ledger.deliver(sale))) break;
    store.acknowledge(sale.number);
    sent += 1;
  }
  return sent;
}
