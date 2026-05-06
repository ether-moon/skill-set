export function checkPromotion(order: any): { ok: boolean; reason?: string } {
  if (order.promoCode && order.promoCode.length > 20) {
    return { ok: false, reason: 'invalid promo code length' };
  }
  return { ok: true };
}
