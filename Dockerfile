# بک‌اند بازارک با FFmpeg (برای ساخت ویدیوی آگهی)
FROM node:20-bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends ffmpeg fonts-dejavu-core \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app/backend
COPY backend/package*.json ./
RUN npm install --omit=dev
COPY backend/ ./
ENV NODE_ENV=production
EXPOSE 10000
CMD ["node", "src/server.js"]
