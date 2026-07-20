import { checkPromotion } from './promotion-check';
import { checkInventory } from './inventory-check';
import { checkCredit } from './credit-check';

export async function placeOrder(req: Request): Promise<Response> {
  const order = await req.json();
  const errors: string[] = [];

  const promo = checkPromotion(order);
  if (!promo.ok) errors.push(`promo: ${promo.reason}`);

  const inv = checkInventory(order);
  if (!inv.ok) errors.push(`inventory: ${inv.reason}`);

  const credit = checkCredit(order);
  if (!credit.ok) errors.push(`credit: ${credit.reason}`);

  if (errors.length > 0) {
    return new Response(JSON.stringify({ errors }), { status: 400 });
  }
  return new Response(JSON.stringify({ ok: true, orderId: 'o-123' }));
}
