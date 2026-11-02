/**
 * The stock ledger: the one record of what a shop holds. Rows are never edited or deleted.
 */

/** What a movement records. */
export enum MovementKind {
  Receipt = "receipt",
  Sale = "sale",
  Return = "return",
  Transfer = "transfer",
  Adjustment = "adjustment",
}

/** Why a count was adjusted by hand. */
export type AdjustmentReason = "damaged" | "lost" | "found" | "miscounted";

/** One row of the ledger: positive in, negative out. */
export interface Movement {
  key: string;
  quantity: number;
  kind: MovementKind;
  at: Date;
  staff: string;
  reason?: AdjustmentReason;
}

/** The ledger of one shop, with the counts computed from it. */
export class Ledger {
  private readonly rows: Movement[] = [];

  /** Appends a movement. The only write the ledger has. */
  append(row: Movement): void {
    this.rows.push(row);
  }

  /** On hand: the sum of a title's movements. */
  onHand(key: string): number {
    return this.rows.filter((r) => r.key === key).reduce((n, r) => n + r.quantity, 0);
  }

  /** Available: on hand minus the copies reserved for customer orders. */
  available(key: string, reserved: number): number {
    return Math.max(0, this.onHand(key) - reserved);
  }

  /** Writes the movement that reverses a row, which is what the stock screen's undo does. */
  reverse(row: Movement, staff: string): Movement {
    const back = { ...row, quantity: -row.quantity, at: new Date(), staff };
    this.append(back);
    return back;
  }
}
