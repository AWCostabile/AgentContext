/**
 * The till's own store: every sale lands here first, and waits here while the shop is offline.
 */
import type { Sale } from "./sale";

/** How many days of sales the store keeps at least. */
export const RETAIN_DAYS = 30;

/** The sales one till has made, in the order it made them. */
export class TillStore {
  private readonly sales: Sale[] = [];
  private sentUpTo = 0;

  constructor(readonly path: string) {}

  /** Records a sale. Called before payment is confirmed on screen. */
  record(sale: Sale): void {
    this.sales.push(sale);
  }

  /** The sales not yet acknowledged by the ledger, oldest first. */
  waiting(): Sale[] {
    return this.sales.slice(this.sentUpTo);
  }

  /** Marks every sale up to and including this number as acknowledged. */
  acknowledge(number: string): void {
    const at = this.sales.findIndex((s) => s.number === number);
    if (at >= this.sentUpTo) this.sentUpTo = at + 1;
  }

  /** The text of the offline badge, or nothing when no sale waits. */
  badge(): string | undefined {
    const n = this.waiting().length;
    return n === 0 ? undefined : `offline: ${n} sales waiting`;
  }
}
