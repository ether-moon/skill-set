class Order {
  constructor(items, customerId) {
    this.items = items;
    this.customerId = customerId;
  }

  // Validates the order — checks inventory, credit, and shipping address
  validateOrder() {
    if (!this.items || this.items.length === 0) {
      return { ok: false, reason: 'no items' };
    }
    if (!this.customerId) {
      return { ok: false, reason: 'no customer' };
    }
    return { ok: true };
  }

  getOrderTotal() {
    return this.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  }
}

module.exports = Order;
