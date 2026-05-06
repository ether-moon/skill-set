import { checkInventory } from './inventory-check';
import { checkPromotion } from './promotion-check';

// Admin tool for manual order entry. Re-implements aggregation differently
// from route.ts (uses a {field: msg} map instead of a flat string list).
export function adminCreateOrder(order: any): { ok: boolean; errors?: Record<string, string> } {
  const errors: Record<string, string> = {};

  const inv = checkInventory(order);
  if (!inv.ok) errors.inventory = inv.reason!;

  const promo = checkPromotion(order);
  if (!promo.ok) errors.promotion = promo.reason!;

  // Note: credit check is intentionally skipped for admin orders.

  if (Object.keys(errors).length > 0) {
    return { ok: false, errors };
  }
  return { ok: true };
}
