# Quick Wins - Time-Boxed Performance Optimizations

Prioritized optimizations by time investment and impact. Start from the top and work down.

## If You Have 1 Hour (High Impact, Low Effort)

### 1. Add `loading="lazy"` to Below-Fold Images

**Impact:** Reduces initial page weight by 40-60%

**Implementation:**
```html
<!-- ❌ BAD: Loading all images eagerly -->
<img src="hero.jpg" alt="Hero">
<img src="content-1.jpg" alt="Content 1">
<img src="content-2.jpg" alt="Content 2">

<!-- ✅ GOOD: Lazy load below-fold images -->
<img src="hero.jpg" alt="Hero" loading="eager" fetchpriority="high">
<img src="content-1.jpg" alt="Content 1" loading="lazy">
<img src="content-2.jpg" alt="Content 2" loading="lazy">
```

**Browser support:** 96% (all modern browsers)

**Common pitfall:** DO NOT lazy load the LCP image (largest image above fold)

---

### 2. Enable Compression (gzip/brotli)

**Impact:** Reduces transfer size by 70-80%

**Implementation:**

**Nginx:**
```nginx
# /etc/nginx/nginx.conf
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript 
           application/json application/javascript application/xml+rss 
           application/rss+xml font/truetype font/opentype 
           application/vnd.ms-fontobject image/svg+xml;

# Brotli (if module installed)
brotli on;
brotli_comp_level 6;
brotli_types text/plain text/css text/xml text/javascript 
             application/json application/javascript application/xml+rss;
```

**Apache:**
```apache
# .htaccess
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css
  AddOutputFilterByType DEFLATE application/javascript application/json
</IfModule>
```

**Express.js:**
```javascript
const compression = require('compression');
app.use(compression());
```

**Common pitfall:** Don't compress images/videos (already compressed)

---

### 3. Add `rel="preconnect"` for Critical Origins

**Impact:** Saves 100-500ms per critical resource

**Implementation:**
```html
<!-- Preconnect to critical third-party origins -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="preconnect" href="https://cdn.example.com">

<!-- For less critical origins, use dns-prefetch -->
<link rel="dns-prefetch" href="https://analytics.example.com">
```

**When to use:**
- Fonts from Google Fonts or similar CDNs
- Critical assets from CDN
- API servers for initial data fetch
- Critical third-party services

**When NOT to use:**
- More than 3-4 origins (dilutes benefit)
- Non-critical resources
- Same-origin resources

---

### 4. Prevent CLS with Image Dimensions

**Impact:** Reduces CLS by 50-80% (prevents layout shifts)

**Implementation:**

```html
<!-- ❌ BAD: No dimensions, causes layout shift -->
<img src="hero.jpg" alt="Hero">
<!-- Page loads → Text appears → Image loads → Text shifts down → CLS: 0.25+ -->

<!-- ✅ GOOD: Explicit dimensions prevent CLS -->
<img src="hero.jpg" alt="Hero" width="1200" height="600">
<!-- Browser reserves space before image loads → No shift! CLS: 0 -->

<!-- ✅ BETTER: Responsive with aspect-ratio CSS -->
<img src="hero.jpg" alt="Hero" style="aspect-ratio: 16/9; width: 100%;">
```

**CSS for all images:**

```css
img {
  max-width: 100%;
  height: auto;
  /* aspect-ratio preserved from width/height attributes */
}

/* Or use aspect-ratio for responsive images */
.responsive-img {
  aspect-ratio: 16/9;
  width: 100%;
  object-fit: cover;
}
```

**For background images:**

```css
.hero {
  background: url('hero.jpg') center/cover;
  aspect-ratio: 16/9;
  /* Reserve space with aspect ratio */
}
```

**How to add dimensions to existing images:**

```bash
# Get image dimensions
identify hero.jpg
# Output: hero.jpg JPEG 1200x600

# Add to HTML
<img src="hero.jpg" alt="Hero" width="1200" height="600">
```

**Common pitfall:** Don't add dimensions to images you plan to lazy load, unless you're also adding `loading="lazy"` attribute

**Browser support:** 100% (width/height attributes), 94% (aspect-ratio CSS)

**SEO Impact:** CLS is a Core Web Vitals ranking factor - fixing this improves Google rankings

**Verification:**
1. Enable "Layout Shift Regions" in Chrome DevTools
2. Reload page
3. Verify no blue highlighting (= no shifts)

---

## If You Have 1 Day (Medium Impact, Medium Effort)

### 5. Implement Code Splitting

**Impact:** Reduces initial bundle by 30-50%

**Core pattern:** Use dynamic `import()` to split routes/heavy components into separate chunks.

```javascript
// ✅ Route-based code splitting (React)
import { lazy, Suspense } from 'react';

const Dashboard = lazy(() => import('./Dashboard'));
const Settings = lazy(() => import('./Settings'));

function App() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

**Verification:** Use webpack-bundle-analyzer or Vite visualizer. Check network tab for separate chunk files.

**-> See [framework-specific.md](framework-specific.md) for Next.js, Vue, Astro, and SvelteKit code splitting patterns**

---

### 6. Optimize LCP Image with `fetchpriority="high"`

**Impact:** Improves LCP by 200-400ms

**Implementation:**
```html
<!-- ❌ BAD: No optimization -->
<img src="hero.jpg" alt="Hero">

<!-- ✅ GOOD: Optimized for LCP -->
<picture>
  <source srcset="hero.avif" type="image/avif">
  <source srcset="hero.webp" type="image/webp">
  <img 
    src="hero.jpg" 
    alt="Hero" 
    width="1200" 
    height="600"
    fetchpriority="high"
    loading="eager"
  >
</picture>

<!-- Even better: Preload the LCP image -->
<head>
  <link rel="preload" as="image" href="hero.webp" fetchpriority="high">
</head>
```

**Identifying your LCP image:**
1. Run Lighthouse
2. Look for "Largest Contentful Paint element"
3. Optimize that specific image

**Modern format conversion:**
```bash
# Using ImageMagick
magick hero.jpg -quality 85 hero.webp
magick hero.jpg -quality 85 hero.avif

# Using cwebp/avifenc
cwebp -q 85 hero.jpg -o hero.webp
avifenc -s 5 hero.jpg hero.avif
```

---

### 7. Add Basic Service Worker for Offline Support

**Impact:** Instant repeat visits, better perceived performance

**Implementation:**
```javascript
// sw.js - Basic caching strategy
const CACHE_NAME = 'v1';
const urlsToCache = [
  '/',
  '/styles.css',
  '/app.js',
  '/logo.png'
];

// Install event: cache static assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});

// Fetch event: serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
  );
});

// Activate event: clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames
          .filter(name => name !== CACHE_NAME)
          .map(name => caches.delete(name))
      );
    })
  );
});
```

**Register service worker:**
```javascript
// Register in your main app file
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js')
      .then(reg => console.log('SW registered:', reg))
      .catch(err => console.log('SW registration failed:', err));
  });
}
```

**Using Workbox (recommended for production):**
```javascript
// Install Workbox
npm install --save-dev workbox-webpack-plugin

// webpack.config.js
const WorkboxPlugin = require('workbox-webpack-plugin');

module.exports = {
  plugins: [
    new WorkboxPlugin.GenerateSW({
      clientsClaim: true,
      skipWaiting: true,
    })
  ]
};
```

---

## If You Have 1 Week (High Impact, High Effort)

### 8. Implement Full Caching Strategy

**Impact:** Very High - enables instant repeat visits, reduces server load

**Key principles:**
- HTML: `no-cache, must-revalidate` (always fresh)
- Hashed static assets (JS/CSS/images): `public, max-age=31536000, immutable`
- API responses: `max-age=60, stale-while-revalidate=600`
- Fonts: long cache + `Access-Control-Allow-Origin: *`

**Service worker strategies** (use Workbox for production):
- Images: CacheFirst (30-day expiry)
- API: NetworkFirst (5-min cache fallback)
- CSS/JS: StaleWhileRevalidate

**-> See [optimization-techniques.md](optimization-techniques.md) for full HTTP headers, Nginx config, Workbox patterns, and CDN configuration**

---

### 9. Optimize Bundle Size with Tree Shaking

**Impact:** 40-60% bundle reduction

**Key actions:**
1. Set `"sideEffects": false` in package.json (or list files with side effects)
2. Use ES module imports: `import { debounce } from 'lodash-es'` not `import _ from 'lodash'`
3. Run `webpack-bundle-analyzer` to find large/duplicate/unused dependencies
4. Ensure webpack `mode: 'production'` with `usedExports: true`

```javascript
// ❌ BAD: Imports entire library (70KB)
import _ from 'lodash';

// ✅ GOOD: Import only what you need (4KB)
import { debounce } from 'lodash-es';
```

---

### 10. Add Performance Monitoring (Lighthouse CI + RUM)

**Impact:** Continuous visibility into performance regressions

**Two complementary approaches:**
1. **Lighthouse CI** - Lab testing in CI/CD pipeline. Install `@lhci/cli`, configure `lighthouserc.json` with score/metric thresholds, run on every PR.
2. **Real User Monitoring (RUM)** - Field data from real users. Use `web-vitals` library to measure CLS, FCP, INP, LCP, TTFB and send to your analytics backend.

**-> See [monitoring.md](monitoring.md) for complete Lighthouse CI config, GitHub Actions integration, RUM setup, APM tools, and custom dashboards**

---

## Priority Matrix

| Optimization | Time | Impact | ROI | Difficulty |
|--------------|------|--------|-----|------------|
| Lazy loading | 1h | High | ⭐⭐⭐⭐⭐ | Easy |
| Compression | 1h | High | ⭐⭐⭐⭐⭐ | Easy |
| Preconnect | 1h | Medium | ⭐⭐⭐⭐ | Easy |
| **CLS prevention** | **1h** | **Very High** | **⭐⭐⭐⭐⭐** | **Easy** |
| Code splitting | 1d | High | ⭐⭐⭐⭐ | Medium |
| LCP optimization | 1d | High | ⭐⭐⭐⭐ | Medium |
| Service worker | 1d | Medium | ⭐⭐⭐ | Medium |
| Full caching | 1w | Very High | ⭐⭐⭐⭐⭐ | Hard |
| Bundle optimization | 1w | High | ⭐⭐⭐⭐ | Hard |
| Monitoring | 1w | Medium | ⭐⭐⭐ | Medium |

## Verification Checklist

After implementing quick wins, verify improvements:

- [ ] Run Lighthouse before/after
- [ ] Check Lighthouse score improved by 10+ points
- [ ] LCP improved by 20%+ (target: <2.5s)
- [ ] INP improved by 20%+ (target: <200ms)
- [ ] CLS improved by 30%+ (target: <0.1)
- [ ] Total bundle size reduced by 20%+
- [ ] Page weight reduced by 30%+
- [ ] Time to Interactive improved by 25%+

---

**Remember:** Start with 1-hour optimizations for immediate wins. These give the best ROI and build momentum for larger optimizations.