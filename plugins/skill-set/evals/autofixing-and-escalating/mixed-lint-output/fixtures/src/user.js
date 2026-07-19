const path = require('path');
const crypto = require('crypto');

class User {
  // recieves a raw user object and returns a hashed version
  constructor(data) {
    this.id = data.id;
    this.passwordHash = crypto
      .createHash('sha256')
      .update(data.password)
      .digest('hex');
  }

  getDisplayName() {
    return this.id;
  }
}

module.exports = User;
