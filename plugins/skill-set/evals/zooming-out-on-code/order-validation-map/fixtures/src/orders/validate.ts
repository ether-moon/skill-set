import { activePromotion } from '../promotions/catalog';
import { inStock } from '../inventory/availability';

export function validateOrder(order: { sku: string }) {
  return activePromotion(order) && inStock(order.sku);
}
