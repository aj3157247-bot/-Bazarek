const ADMIN_EMAIL = (process.env.ADMIN_EMAIL || '').trim().toLowerCase();
const ADMIN_PASS = process.env.ADMIN_PASS || '';

function verifyAdmin(req, res, next) {
  const email = String(req.headers['x-admin-email'] || '').trim().toLowerCase();
  const password = String(req.headers['x-admin-password'] || '');

  if (ADMIN_EMAIL && ADMIN_PASS && email === ADMIN_EMAIL && password === ADMIN_PASS) {
    return next();
  }

  return res.status(403).json({ error: 'دسترسی غیرمجاز.' });
}

module.exports = verifyAdmin;
