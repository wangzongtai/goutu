const CACHE_NAME = 'yuyu-goutu-v3';
const PRE_CACHE = ['./index.html', './manifest.webmanifest'];

// 安装：首次访问把核心文件存入本地缓存（离线兜底）
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(PRE_CACHE).catch(() => {}))
      .then(() => self.skipWaiting())
  );
});

// 激活：清理所有旧版本缓存，并立即接管页面
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(names => Promise.all(
      names.filter(n => n !== CACHE_NAME).map(n => caches.delete(n))
    ))
  );
  self.clients.claim();
});

// 网络优先：有网拿最新版；断网读取本地缓存，实现离线可用
self.addEventListener('fetch', event => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== location.origin) return;

  event.respondWith(
    fetch(req)
      .then(res => {
        if (res && res.ok) {
          const copy = res.clone();
          caches.open(CACHE_NAME).then(c => c.put(req, copy)).catch(() => {});
        }
        return res;
      })
      .catch(() => caches.match(req).then(hit => hit || caches.match('./index.html')))
  );
});
