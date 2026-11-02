/**
 * A sale as the till makes it: lines, a payment and a number of its own.
 */

/** How a customer paid. */
export enum PaymentMethod {
  Cash = "cash",
  Card = "card",
  GiftCard = "gift-card",
}

/** One book on a sale. A title the ledger cache does not know is sold as not found. */
export interface SaleLine {
  /** The ISBN, or the shop-local code of a secondhand copy. */
  key: string;
  priceCents: number;
  notFound?: boolean;
}

/** A completed sale, written to the till's store before anything else. */
export interface Sale {
  number: string;
  lines: SaleLine[];
  method: PaymentMethod;
  /** The card terminal's approval code; the till never sees a card number. */
  approval?: string;
  madeAt: Date;
}

/**
 * Makes a sale number from the till's letter, the date and a counter. The number is printed
 * on the receipt, so it must be unique without the ledger.
 */
export function saleNumber(till: string, day: Date, counter: number): string {
  const date = day.toISOString().slice(0, 10).replaceAll("-", "");
  return [till, date, String(counter).padStart(4, "0")].join("-");
}

/** Totals a sale's lines. */
export function total(sale: Sale): number {
  return sale.lines.reduce((sum, line) => sum + line.priceCents, 0);
}

/** Whether a sale can complete without the connection. Gift cards need the ledger's balance. */
export function completesOffline(method: PaymentMethod): boolean {
  return method !== PaymentMethod.GiftCard;
}
