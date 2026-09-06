const jwt = require('jsonwebtoken');

function requireAdmin(req, res, next) {
  try {
    const auth = req.headers.authorization || '';
    if (!auth.startsWith('Bearer ')) return res.status(401).json({ error: 'نشست مدیریت پیدا نشد.' });
    const payload = jwt.verify(auth.slice(7), process.env.ADMIN_SESSION_SECRET);
    if (payload.role !== 'admin') return res.status(403).json({ error: 'دسترسی غیرمجاز.' });
    req.admin = payload;
    next();
  } catch (_) {
    return res.status(401).json({ error: 'نشست مدیریت نامعتبر یا منقضی شده است.' });
  }
}

module.exports = requireAdmin;
