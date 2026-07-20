import { validateOrder } from './validate';

export const createManualOrder = (order: { sku: string }) => validateOrder(order);
