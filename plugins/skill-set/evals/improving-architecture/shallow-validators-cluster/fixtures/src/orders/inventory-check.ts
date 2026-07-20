export function checkInventory(order: any): { ok: boolean; reason?: string } {
  if (!order.items || order.items.length === 0) {
    return { ok: false, reason: 'empty cart' };
  }
  for (const item of order.items) {
    if (item.quantity > 100) {
      return { ok: false, reason: `quantity too high for ${item.sku}` };
    }
  }
  return { ok: true };
}
