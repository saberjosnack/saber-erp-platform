// Saber ERP — Service Worker (نسخة تحديث تلقائي)
// كل ما ترفع index.html جديد، غيّر رقم النسخة هون تحت (CACHE_NAME) وبيتحدث تلقائيًا عند كل الأجهزة
const CACHE_NAME = 'saber-erp-v1'; // ⚠️ زيّد الرقم (v4, v5...) كل ما تعمل تحديث كبير
const OFFLINE_URLS = ['./', './index.html'];
self.addEventListener('install', (event) => {
  self.skipWaiting(); // يفعّل النسخة الجديدة فورًا بدون انتظار إغلاق كل التبويبات
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(OFFLINE_URLS).catch(()=>{}))
  );
});
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim()) // ياخد تحكم فوري بكل الصفحات المفتوحة
  );
});
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  const url = new URL(event.request.url);
  const isSameOrigin = url.origin === self.location.origin;

  // 🔒 طلبات البيانات الحيّة (Supabase وأي نطاق خارجي) — ما نخزّنها كاش أبدًا، ولا نرجع نسخة
  // قديمة عند أي فشل. لازم شبكة حقيقية دايمًا عشان ما تظهر أرقام قديمة (ساعات دوام، مبيعات،
  // عملاء...) مباشرة بعد أي إجراء (تسجيل خروج، حفظ طلب، إلخ) بسبب كاش المتصفح.
  if (!isSameOrigin) {
    event.respondWith(fetch(event.request, { cache: 'no-store' }));
    return;
  }

  // ملفات التطبيق نفسها: الشبكة أولاً دايمًا (مع تجاوز كاش المتصفح صراحةً عشان يجيب آخر
  // تحديث فعليًا)، ولو مقطوع الإنترنت يرجع للنسخة المحفوظة
  event.respondWith(
    fetch(event.request, { cache: 'no-store' })
      .then((response) => {
        const copy = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy)).catch(()=>{});
        return response;
      })
      .catch(() => caches.match(event.request).then((cached) => cached || caches.match('./index.html')))
  );
});
