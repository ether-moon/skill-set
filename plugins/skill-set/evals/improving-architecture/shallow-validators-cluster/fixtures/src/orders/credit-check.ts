export function checkCredit(order: any): { ok: boolean; reason?: string } {
  if (!order.creditCardLast4) {
    return { ok: false, reason: 'no payment method' };
  }
  return { ok: true };
}
