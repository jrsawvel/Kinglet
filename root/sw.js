// sw.js
self.addEventListener('install', function(e) {
 e.waitUntil(
   // after the service worker is installed,
   // open a new cache
   caches.open('soupmode-pwa-cache').then(function(cache) {
     // add all URLs of resources we want to cache
     return cache.addAll([
       '/article/help',
       '/css/kinglet.css',
       '/css/soupmodemenu.css',
       '/css/meanmenu.css',
       '/javascript/main.js',
       '/javascript/jquery.meanmenu.min.js',
       '/javascript/minified.js',
     ]);
   })
 );
});

self.addEventListener('fetch', function(event) {
    console.log(event.request.url);
  event.respondWith(
    caches.match(event.request).then(function(response) {
  return response || fetch(event.request);
  })
 );
});
