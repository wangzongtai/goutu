/* 构图助手 离线缓存 —— 先用本地，后台自动更新
   效果：
   1) 打开是瞬时的（不再等网络，断网也能开）
   2) 你在 GitHub 改了 index.html 重新上传后，手机会在后台悄悄存新版：
      第一次打开还是旧版，关掉再打开就是新版。
   —— 不需要改版本号，不需要清缓存。 */

const CACHE = 'goutu-cache';
const ASSETS = ['./', './index.html', './manifest.webmanifest', './icon-192.png', './icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => c.addAll(ASSETS).catch(() => {}))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== location.origin) return;   // 只接管本站资源

  e.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const hit = await cache.match(req, { ignoreSearch: true });

    // 后台去网上拿新的，拿到就更新缓存（不管这次用不用得上）
    const refresh = fetch(req).then(res => {
      if (res && res.ok) cache.put(req, res.clone()).catch(() => {});
      return res;
    }).catch(() => null);

    if (hit) return hit;          // 有本地：立刻给，同时后台更新
    const res = await refresh;    // 没本地：只能等网络
    if (res) return res;
    return caches.match('./index.html');
  })());
});
