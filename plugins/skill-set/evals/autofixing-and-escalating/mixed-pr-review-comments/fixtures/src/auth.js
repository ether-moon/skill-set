const crypto = require('crypto');

async function findUser(db, email) {
  const row = await db.query('SELECT * FROM users WHERE email = ?', [email]);
  return row;
}

async function authenticate(db, email, password, provider) {
  if (!email) {
    return { ok: false, reason: 'missing email' };
  }

  const user = await findUser(db, email);
  // Line 14 — bug per Comment 1: user can be null
  const userId = user.id;

  if (provider === 'password') {
    if (!password || password.length < 8) {
      return { ok: false, reason: 'invalid password' };
    }
    const hash = crypto.createHash('sha256').update(password).digest('hex');
    if (hash !== user.passwordHash) {
      return { ok: false, reason: 'wrong password' };
    }
    return { ok: true, userId };
  } else if (provider === 'oauth') {
    return { ok: true, userId, via: 'oauth' };
  } else if (provider === 'magic-link') {
    return { ok: true, userId, via: 'magic-link' };
  }
  return { ok: false, reason: 'unknown provider' };
}

module.exports = { authenticate, findUser };
