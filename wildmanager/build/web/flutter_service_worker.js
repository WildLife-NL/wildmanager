'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "4e17d20f8ba71b043f47f71608870e7c",
"assets/AssetManifest.bin.json": "ea3e21523c416824c73e8df2c46b47c6",
"assets/AssetManifest.json": "50a06cb33615236d9eff84b0bc766c68",
"assets/assets/app_logo.png": "5dcef449791fa27946b3d35ad8803796",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/fonts/MaterialIcons-Regular.otf": "53e77fcc4ca93b73c398e34939026015",
"assets/NOTICES": "845a983547ad38bff5a74e8655348bd7",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/packages/wildlifenl_assets/assets/animals/bever.png": "a8139588b3c861d468af875a3da9d682",
"assets/packages/wildlifenl_assets/assets/animals/boommarter.png": "b1f70bd7b49ee1cfa9706d64789d8d54",
"assets/packages/wildlifenl_assets/assets/animals/bunzing.png": "bd556c643543dcf5d93a8fe56418eace",
"assets/packages/wildlifenl_assets/assets/animals/damhert.png": "e9926f673b100136bc36c32293779d06",
"assets/packages/wildlifenl_assets/assets/animals/das.png": "4e562b232abe873a3c46976d0bbb2b9d",
"assets/packages/wildlifenl_assets/assets/animals/edelhert.png": "50669b03f2e4d49d44864dc390587311",
"assets/packages/wildlifenl_assets/assets/animals/eekhoorn.png": "224c428277dc4ebadfc8085a26ae9239",
"assets/packages/wildlifenl_assets/assets/animals/egel.png": "2d2b08feae0926569c8448b592c2106c",
"assets/packages/wildlifenl_assets/assets/animals/europese%2520nerts.png": "e2300fd660b030ed420182fe6a6f0414",
"assets/packages/wildlifenl_assets/assets/animals/exmoor%2520pony.png": "92ec9fee11ded8ebf19ad55498b15062",
"assets/packages/wildlifenl_assets/assets/animals/galloway.png": "b02f1b0a669eab3619a65b3c109f6bfb",
"assets/packages/wildlifenl_assets/assets/animals/goudjakhals.png": "c144f487b453e7267b1ae382489c1142",
"assets/packages/wildlifenl_assets/assets/animals/haas.png": "91566f2cbec4a806e3b84720833c782a",
"assets/packages/wildlifenl_assets/assets/animals/hermelijn.png": "56d13562e0f9207c2f4505428da159a1",
"assets/packages/wildlifenl_assets/assets/animals/hooglander.png": "8442c143bc008566eac9e1ed7d80dd78",
"assets/packages/wildlifenl_assets/assets/animals/konijn.png": "af1ff40caa7a13e34e482886bcdc6c11",
"assets/packages/wildlifenl_assets/assets/animals/konikpaard.png": "a2b3678cc2ab6d1cb80927dc7100f701",
"assets/packages/wildlifenl_assets/assets/animals/otter.png": "fe99c3dfdf0431858138e7cc833bbb2a",
"assets/packages/wildlifenl_assets/assets/animals/ree.png": "c194531c3cfea00f0cb09cb2b30c23be",
"assets/packages/wildlifenl_assets/assets/animals/shetland%2520pony.png": "e1645cc39c1cf78c5f64f3df1df8fd60",
"assets/packages/wildlifenl_assets/assets/animals/steenmarter.png": "c95ad1e358b808831a544503c9e0b602",
"assets/packages/wildlifenl_assets/assets/animals/tauros.png": "96491ccbe8c31bece371b63377a84280",
"assets/packages/wildlifenl_assets/assets/animals/vos.png": "3d912232fcd98fe3566e0ac4526d8d14",
"assets/packages/wildlifenl_assets/assets/animals/wezel.png": "5137302561500f3e882e1053ecefeb92",
"assets/packages/wildlifenl_assets/assets/animals/wild%2520kat.png": "15f602e7f8d8122029c008b54f98792f",
"assets/packages/wildlifenl_assets/assets/animals/wild%2520zwijn.png": "f62849367a812be5d1cfc83939edb830",
"assets/packages/wildlifenl_assets/assets/animals/wisent.png": "90a7d0cfb05e414393f332cb25ba480c",
"assets/packages/wildlifenl_assets/assets/animals/woelrat.png": "6e89e51c94bb138b8149af2cf7b5eca5",
"assets/packages/wildlifenl_assets/assets/animals/wolf.png": "0e3254b798e90b4c9fa8d716c51545e9",
"assets/packages/wildlifenl_assets/assets/icons/accident.png": "7786a3201b5a865d93e5b5fc63b8b685",
"assets/packages/wildlifenl_assets/assets/icons/agriculture.png": "64af7eb2ccde989769103bb65dfc8eb0",
"assets/packages/wildlifenl_assets/assets/icons/animals/beaver.png": "5950e8ac8c6fbc21ae3f244f40542737",
"assets/packages/wildlifenl_assets/assets/icons/animals/boommarten.png": "b0117ae7d0c93c301e036fdc0db587ae",
"assets/packages/wildlifenl_assets/assets/icons/animals/damhert.png": "55dddef9a73032ad53ff21e46d298afe",
"assets/packages/wildlifenl_assets/assets/icons/animals/das.png": "eef7d6bee7764efb9f461d793118e314",
"assets/packages/wildlifenl_assets/assets/icons/animals/eekhoorn.png": "ce15777a8f4ab69d2fb686d46a14d300",
"assets/packages/wildlifenl_assets/assets/icons/animals/egel.png": "9b6f908c71e9b56f6d6da200cb65ef46",
"assets/packages/wildlifenl_assets/assets/icons/animals/hooglander.png": "beb775a33f032257ca56dabc8b21eaeb",
"assets/packages/wildlifenl_assets/assets/icons/animals/ree.png": "624f8c111ae1d21d30207897b20c0e4b",
"assets/packages/wildlifenl_assets/assets/icons/animals/vos.png": "1ed9c512d6c52a6b6e997ad1822afdb7",
"assets/packages/wildlifenl_assets/assets/icons/animals/wild_zwijn.png": "67a639bf3e159d9ee38ba5fd7f9c5212",
"assets/packages/wildlifenl_assets/assets/icons/animals/winsent.png": "06bcb69a2f5241ee82250803483ebc7b",
"assets/packages/wildlifenl_assets/assets/icons/animals/wolf.png": "85bf108eacdffb433fd1641ddd7234f4",
"assets/packages/wildlifenl_assets/assets/icons/binoculars.png": "f2832188ac0f273e2bcce5ad27d38b43",
"assets/packages/wildlifenl_assets/assets/icons/category/evenhoevigen.png": "4d1973c258ce2a35ece02c6ddf0b4701",
"assets/packages/wildlifenl_assets/assets/icons/category/knaagdieren.png": "730c0b671d7817c377ce19ebe9bba074",
"assets/packages/wildlifenl_assets/assets/icons/category/roofdieren.png": "6b59396ee2b97bd18ffe83692f3eff4b",
"assets/packages/wildlifenl_assets/assets/icons/deer.png": "e43f7db3b368316f705e12ac1d7477f9",
"assets/packages/wildlifenl_assets/assets/icons/gender/female_gender.png": "91a7b844e6a919c4263e4a07d382d800",
"assets/packages/wildlifenl_assets/assets/icons/gender/male_gender.png": "fbfb9f90e44a791d9e3f0a43a97579c4",
"assets/packages/wildlifenl_assets/assets/icons/gender/unknown_gender.png": "572603c5afda5bc47a87f08f6ef84537",
"assets/packages/wildlifenl_assets/assets/icons/marked_earth.png": "077a92eb7739f4ca14c0dab7c864e043",
"assets/packages/wildlifenl_assets/assets/icons/my_report.png": "275cc86283365c89fe6d5e6f4e4cd7b4",
"assets/packages/wildlifenl_assets/assets/icons/possesion/gewassen/apple.svg": "8ed36dc035a6701b098e48709c103ba3",
"assets/packages/wildlifenl_assets/assets/icons/possesion/gewassen/corn.svg": "6dc98cafa439e613c4c92557dd3a6599",
"assets/packages/wildlifenl_assets/assets/icons/possesion/gewassen/grass.svg": "8d0d834fe4654cdf022135f366a68604",
"assets/packages/wildlifenl_assets/assets/icons/possesion/gewassen/radish_2.svg": "50d82993f55fc235f8194cbc47122756",
"assets/packages/wildlifenl_assets/assets/icons/possesion/gewassen/tomato.svg": "e814487f6ab70cac3fd7b2de26c3be50",
"assets/packages/wildlifenl_assets/assets/icons/possesion/gewassen/tulip_2.svg": "bbdde187c0ce442f4233dab282f62da8",
"assets/packages/wildlifenl_assets/assets/icons/possesion/gewassen/wheat.svg": "476e5d1408d5c86bd1186d4006044ae2",
"assets/packages/wildlifenl_assets/assets/icons/possesion/impacted_area_type.png": "c688f5cce04b4b86451e4796a573cc1f",
"assets/packages/wildlifenl_assets/assets/icons/questionnaire/arrow.png": "01b204e0b817e3098552cc6ce336d34f",
"assets/packages/wildlifenl_assets/assets/icons/questionnaire/arrow_forward.png": "7d8267bfd1aed78f485da56553e4afd6",
"assets/packages/wildlifenl_assets/assets/icons/questionnaire/save.png": "ea1d8d3c78a7fa0f58ce5bc0a093dbad",
"assets/packages/wildlifenl_assets/assets/icons/rapporteren/accident_icon.png": "33e53bfe608c1c3e058e3367db8397de",
"assets/packages/wildlifenl_assets/assets/icons/rapporteren/crop_icon.png": "ef56ad73a14828bc31231cba6069be88",
"assets/packages/wildlifenl_assets/assets/icons/rapporteren/health_icon.png": "5ff1c88117f0bb65c463059875e0064a",
"assets/packages/wildlifenl_assets/assets/icons/rapporteren/sighting_icon.png": "90798a7cf5d122d9a439c6d973048413",
"assets/packages/wildlifenl_assets/assets/icons/report.png": "9d9b3237d596dee529bae029991bd480",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "80d8280b8b7a828fcaee2194a4ec17fe",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "25df11ca3e9ae7726b6ef4f59ad525e5",
"/": "25df11ca3e9ae7726b6ef4f59ad525e5",
"main.dart.js": "5c5503fd1245be65f877f8dbdf92a285",
"manifest.json": "77509e05d24ea38fd010c5948ffe1567",
"version.json": "9b9a6ac38961a01cb4710696d01556b5"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
