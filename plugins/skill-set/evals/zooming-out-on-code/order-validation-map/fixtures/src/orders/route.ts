import { validateOrder } from './validate';

export const placeOrder = (order: { sku: string }) => validateOrder(order);
