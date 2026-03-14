# Mobile Sinks — Kotlin/Android, Swift/iOS

---

## Kotlin/Android Sinks

### RCE

`Runtime.getRuntime().exec()`, `ProcessBuilder()`, JavaScript bridges via `WebView.addJavascriptInterface()` (pre-API 17: all public methods exposed), `ScriptEngine.eval()`

### Intent-Based Attacks

**Exported components:** `android:exported="true"` on Activities, Services, BroadcastReceivers, ContentProviders without permission checks

**Intent injection:** `getIntent().getStringExtra()` passed to `startActivity()` / `sendBroadcast()` / `startService()`, `PendingIntent` with mutable flags (`FLAG_MUTABLE`)

**Deep link hijacking:** custom scheme handlers (`myapp://`) without origin validation, `intent://` scheme for cross-app exploitation

### Data Storage

`SharedPreferences` in world-readable mode, `MODE_WORLD_READABLE` / `MODE_WORLD_WRITABLE` (deprecated but still seen), unencrypted SQLite databases, sensitive data in `external storage` (SD card — world-readable), `ContentProvider` without proper permissions, backup enabled (`android:allowBackup="true"`) exposing app data

### WebView Sinks

`setJavaScriptEnabled(true)` + `loadUrl(user_input)`, `evaluateJavascript()` with tainted strings, `setAllowFileAccessFromFileURLs(true)` (file:// XSS to data theft), `setAllowUniversalAccessFromFileURLs(true)`, `WebViewClient.shouldOverrideUrlLoading()` bypass

### Network

`HttpURLConnection` / `OkHttpClient` with user-controlled URL (SSRF), `TrustManager` accepting all certificates, `HostnameVerifier` returning true for all hosts, certificate pinning bypass via custom `SSLSocketFactory`

### SQLi

`rawQuery()` with string concat, `execSQL()` with interpolation, Room `@RawQuery` with unsanitized input, `ContentResolver.query()` with tainted selection args

### Crypto

`SecureRandom` seeded with predictable value, `ECB` mode in `Cipher.getInstance()`, hardcoded keys in source/resources, `KeyStore` without strong password, `Cipher.getInstance("AES")` defaults to ECB on some implementations

---

## Swift/iOS Sinks

### RCE (Limited)

`Process()` (macOS only — `Process.launchPath`, `Process.arguments`), `NSTask` (Objective-C bridge), JavaScript execution via `WKWebView.evaluateJavaScript()` with tainted strings

### WebView Sinks

`WKWebView.load(URLRequest)` with user-controlled URL, `WKWebView.evaluateJavaScript()`, `WKScriptMessageHandler` receiving unvalidated messages, `WKNavigationDelegate` allowing arbitrary navigation, `UIWebView` (deprecated — no security sandboxing, avoid entirely)

### Data Storage

`UserDefaults` for sensitive data (unencrypted plist), `NSKeyedArchiver` / `NSKeyedUnarchiver` (deserialization attacks), Keychain without `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, SQLite databases in app container without encryption, Core Data with unencrypted persistent stores

### Network

`URLSession.dataTask()` with user-controlled URL (SSRF), `ATS` (App Transport Security) exceptions allowing HTTP, custom `URLSessionDelegate` accepting invalid certificates, `ServerTrustPolicy.disableEvaluation` in Alamofire

### URL Scheme Handling

`application(_:open:options:)` without origin validation, custom URL schemes (`myapp://`) — no authentication of caller, Universal Links misconfiguration allowing hijacking, `SFSafariViewController` URL validation bypass

### SQLi

`sqlite3_exec()` via C bridge with string interpolation, `GRDB.Database.execute()` with string building, `FMDB` `executeQuery()` with string concat
