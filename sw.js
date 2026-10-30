/* Arooma service worker: offline app shell.
   __BUILD__ is replaced with the commit SHA by the GitHub Actions workflow,
   so each deploy gets a fresh cache and old ones are removed. */
const BUILD = '__BUILD__';
const CACHE = 'arooma-' + BUILD;
const SHELL = [
  './',
  'index.html',
  'manifest.webmanifest',
  'assets/icons/icon.svg',
  'assets/icons/icon-192.png',
  'assets/icons/icon-512.png',
  'assets/icons/apple-touch-icon.png',
  'assets/icons/favicon-32.png',
  'assets/collectibles/cards/dior-front.svg',
  'assets/collectibles/cards/dior-back.svg',
  'assets/collectibles/cards/hawas-front.svg',
  'assets/collectibles/cards/hawas-back.svg',
  'assets/collectibles/cards/myslf-front.svg',
  'assets/collectibles/cards/myslf-back.svg',
  'assets/collectibles/cards/prodigy-front.svg',
  'assets/collectibles/cards/prodigy-back.svg'
];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k.startsWith('arooma-') && k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  // Pages: network first so a new deploy shows up, cached copy when offline.
  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put('index.html', copy));
          return res;
        })
        .catch(() => caches.match('index.html'))
    );
    return;
  }

  // Everything else: cache first, then network and remember it.
  event.respondWith(
    caches.match(req).then((hit) => hit || fetch(req).then((res) => {
      const copy = res.clone();
      caches.open(CACHE).then((c) => c.put(req, copy));
      return res;
    }))
  );
});
