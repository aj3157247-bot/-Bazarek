// ساخت ویدیوی کوتاه (MP4، عمودی ۹:۱۶) از عکس‌های آگهی برای تیک‌تاک، شورتس، ریلز و واتساپ.
// نیاز: FFmpeg روی سرور (در Dockerfile نصب می‌شود). اگر FFmpeg نبود، خطای واضح برمی‌گرداند و بقیه‌ی سرور دست‌نخورده می‌ماند.
const { spawn } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');

const W = 720, H = 1280;          // عمودی ۹:۱۶
const SECONDS_PER_IMAGE = 3;      // هر عکس ۳ ثانیه
const MAX_IMAGES = 5;             // حداکثر ۵ عکس = ۱۵ ثانیه
const FONT_CANDIDATES = [
  '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
  '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf',
];

function run(cmd, args) {
  return new Promise((resolve, reject) => {
    const p = spawn(cmd, args);
    let err = '';
    p.stderr.on('data', (d) => { err += d.toString(); if (err.length > 4000) err = err.slice(-4000); });
    p.on('error', (e) => reject(new Error(e.code === 'ENOENT' ? 'FFmpeg روی سرور نصب نیست.' : e.message)));
    p.on('close', (code) => (code === 0 ? resolve() : reject(new Error(`ffmpeg exit ${code}: ${err.slice(-600)}`))));
  });
}

// متن را برای فیلتر drawtext امن می‌کند (کاراکترهای ویژه‌ی FFmpeg حذف می‌شوند)
function safeText(t, max = 60) {
  return String(t || '').replace(/[\\:'%\[\]{};,]/g, ' ').replace(/\s+/g, ' ').trim().slice(0, max);
}

async function downloadImage(url, dest) {
  const r = await fetch(url);
  if (!r.ok) throw new Error(`image ${r.status}`);
  const buf = Buffer.from(await r.arrayBuffer());
  if (buf.length > 8 * 1024 * 1024) throw new Error('image too large');
  fs.writeFileSync(dest, buf);
}

/**
 * product: { title, price, currency, province, id, image_url (JSON string or array) }
 * returns: { file, cleanup() }
 */
async function buildListingVideo(product) {
  let images = [];
  try { images = Array.isArray(product.image_url) ? product.image_url : JSON.parse(product.image_url || '[]'); } catch (_) { images = []; }
  images = images.filter((u) => /^https?:\/\//i.test(String(u))).slice(0, MAX_IMAGES);
  if (!images.length) throw new Error('آگهی عکس ندارد.');

  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'bzv-'));
  const cleanup = () => { try { fs.rmSync(dir, { recursive: true, force: true }); } catch (_) {} };
  try {
    const inputs = [];
    for (let i = 0; i < images.length; i++) {
      const p = path.join(dir, `img${i}.jpg`);
      await downloadImage(images[i], p);
      inputs.push(p);
    }
    const font = FONT_CANDIDATES.find((f) => fs.existsSync(f));
    const price = Number(product.price) > 0 ? `${Number(product.price).toLocaleString('en-US')} ${String(product.currency).toUpperCase() === 'USD' ? 'USD' : 'AFN'}` : 'توافقی';
    const title = safeText(product.title, 48);
    const place = safeText(product.province, 30);
    const bottom = [price, place].filter(Boolean).join('   |   ');
    const out = path.join(dir, 'out.mp4');

    // هر عکس: مقیاس و پر کردن کادر عمودی (بدون برش موضوع با پس‌زمینه‌ی محو)
    const parts = inputs.map((_, i) =>
      `[${i}:v]scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2:color=0x111111,` +
      `fps=25,format=yuv420p,setsar=1,trim=duration=${SECONDS_PER_IMAGE}[v${i}]`
    );
    const concatIn = inputs.map((_, i) => `[v${i}]`).join('');
    let fc = `${parts.join(';')};${concatIn}concat=n=${inputs.length}:v=1:a=0[cat]`;
    if (font) {
      fc += `;[cat]drawtext=fontfile=${font}:text='${title}':fontcolor=white:fontsize=44:box=1:boxcolor=black@0.55:boxborderw=18:x=(w-text_w)/2:y=h*0.08,` +
            `drawtext=fontfile=${font}:text='${bottom}':fontcolor=yellow:fontsize=38:box=1:boxcolor=black@0.6:boxborderw=16:x=(w-text_w)/2:y=h*0.84,` +
            `drawtext=fontfile=${font}:text='bazarek.pages.dev':fontcolor=white@0.9:fontsize=34:x=(w-text_w)/2:y=h*0.93[vout]`;
    } else {
      fc += `;[cat]null[vout]`;
    }

    const args = ['-y'];
    inputs.forEach((p) => args.push('-loop', '1', '-t', String(SECONDS_PER_IMAGE), '-i', p));
    args.push('-filter_complex', fc, '-map', '[vout]', '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '28',
      '-pix_fmt', 'yuv420p', '-movflags', '+faststart', '-t', String(inputs.length * SECONDS_PER_IMAGE), out);
    await run('ffmpeg', args);

    if (!fs.existsSync(out) || fs.statSync(out).size < 1000) throw new Error('ویدیو ساخته نشد.');
    return { file: out, cleanup, seconds: inputs.length * SECONDS_PER_IMAGE };
  } catch (e) {
    cleanup();
    throw e;
  }
}

module.exports = { buildListingVideo };
