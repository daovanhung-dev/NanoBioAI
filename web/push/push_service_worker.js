self.addEventListener('push', (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (_) {
    payload = {};
  }

  const title = typeof payload.title === 'string' ? payload.title : 'NanoBio';
  const options = {
    body: typeof payload.body === 'string'
      ? payload.body
      : 'Bạn có một lời nhắc. Mở ứng dụng để xem.',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'nanobio-reminder',
    renotify: false,
    data: { url: typeof payload.url === 'string' ? payload.url : '/' },
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const target = new URL(
    event.notification.data && event.notification.data.url
      ? event.notification.data.url
      : '/',
    self.location.origin,
  );
  if (target.origin !== self.location.origin) return;

  event.waitUntil((async () => {
    const clients = await self.clients.matchAll({
      type: 'window',
      includeUncontrolled: true,
    });
    for (const client of clients) {
      if (new URL(client.url).origin === self.location.origin) {
        if (client.url !== target.href && typeof client.navigate === 'function') {
          await client.navigate(target.href);
        }
        await client.focus();
        return;
      }
    }
    await self.clients.openWindow(target.href);
  })());
});
