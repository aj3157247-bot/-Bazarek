# Bazarek Web — Deploy Fix

این فایل برای رفع خطای Deploy سایت Flutter Web در Render است.

خطای قبلی:
`Cannot change ownership ... Invalid argument`
هنگام دانلود/استخراج Gradle Wrapper توسط Flutter داخل Debian.

## فایل تغییرکرده

فقط:
- `Dockerfile.web`

`nginx.web.conf` از نسخه فعلی پروژه استفاده می‌شود و نیازی به تغییر ندارد.

## نصب

1. فایل `Dockerfile.web` موجود در ریشه پروژه را با فایل داخل این ZIP جایگزین کن.
2. Commit و Push به GitHub.
3. در Render سرویس `bazarek-web` را دوباره Deploy کن.

## تنظیمات Render

- Root Directory: خالی
- Runtime: Docker
- Docker Build Context Directory: `.`
- Dockerfile Path: `./Dockerfile.web`
- Docker Command: خالی
- Pre-Deploy Command: خالی
- Health Check Path: `/`
- Auto-Deploy: On Commit

Backend را تغییر نده:
- Root Directory: `backend`
- Build Command: `npm install`
- Start Command: `node src/server.js`

این نسخه برای Build سایت از Docker image دارای Flutter استفاده می‌کند تا وابسته به دانلود و استخراج Gradle Wrapper در مرحله Build نباشد.
