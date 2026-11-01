/**
 * Title keys: a thirteen-digit ISBN, or a shop-local code for a copy without one.
 */

/** Whether a key is a thirteen-digit ISBN with a valid check digit. */
export function isIsbn(key: string): boolean {
  if (!/^\d{13}$/.test(key)) return false;
  const digits = [...key].map(Number);
  const sum = digits.slice(0, 12).reduce((s, d, i) => s + d * (i % 2 === 0 ? 1 : 3), 0);
  return (10 - (sum % 10)) % 10 === digits[12];
}

/** Makes the shop-local code printed on a secondhand copy's label. */
export function localCode(serial: number): string {
  return "QF-" + String(serial).padStart(6, "0");
}
