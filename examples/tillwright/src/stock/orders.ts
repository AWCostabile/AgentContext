/**
 * Customer orders: a book a customer asked for that the shop does not hold.
 */

/** Where an order is in its life. */
export enum OrderState {
  Placed = "placed",
  Reserved = "reserved",
  Collected = "collected",
  Released = "released",
}

/** One order, from the request to the collection. */
export interface CustomerOrder {
  id: string;
  key: string;
  customer: string;
  contact: string;
  state: OrderState;
  placedAt: Date;
  reservedAt?: Date;
}

/** How long a reserved copy waits for its customer. */
export const HOLD_DAYS = 14;

/** Reserves a received copy for the oldest placed order of that title, if there is one. */
export function reserve(orders: CustomerOrder[], key: string, now: Date): CustomerOrder | undefined {
  const next = orders
    .filter((o) => o.key === key && o.state === OrderState.Placed)
    .sort((a, b) => a.placedAt.getTime() - b.placedAt.getTime())[0];
  if (next) Object.assign(next, { state: OrderState.Reserved, reservedAt: now });
  return next;
}

/** Whether a reservation has lapsed and its copy should return to available stock. */
export function lapsed(order: CustomerOrder, now: Date): boolean {
  if (order.state !== OrderState.Reserved || !order.reservedAt) return false;
  return now.getTime() - order.reservedAt.getTime() > HOLD_DAYS * 86_400_000;
}
