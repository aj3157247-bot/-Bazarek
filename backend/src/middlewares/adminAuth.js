const ADMIN_EMAIL = "abdullahjafari712@gmail.com";
const ADMIN_PASS = "05050505";

function verifyAdmin(req, res, next) {
  const { email, password } = req.headers;

  if (email === ADMIN_EMAIL && password === ADMIN_PASS) {
    return next();
  }

  return res.status(403).json({ error: "دسترسی غیرمجاز! فقط ادمین کل اجازه ورود دارد." });
}

module.exports = verifyAdmin;
