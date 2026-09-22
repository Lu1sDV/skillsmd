# Mobile App Security — Attack Domain Reference

> Coverage current as of 2026-06

Load this file when the target includes Android or iOS applications, hybrid/React-Native/Flutter apps, mobile backend APIs accessed by a mobile client, or mobile SDK integrations. Pairs with `references/sinks/mobile.md` (sink-level code audit) — this file covers attack techniques and exploitation patterns, not sink lists.

---

## Android — IPC & Intent Attacks

### Intent Redirect / Confused Deputy

- Exported `Activity` / `Service` / `BroadcastReceiver` with no permission check receives an intent whose extras contain a nested `Intent` (often via `getParcelableExtra("extra_intent")`) which the component then forwards with its own elevated privileges — allows arbitrary URI open, arbitrary Activity start, or permission escalation.
- Look for: `startActivity(getIntent().getParcelableExtra(...))`, `startActivityForResult`, forwarded `PendingIntent` with mutable flags.
- Detection: `adb shell dumpsys package <pkg> | grep -A2 "Activity\|Service\|Receiver"` lists exported components; `drozer app.activity.info -a <pkg>` enumerates exported with permissions.
- Exploit: `adb shell am start -n <pkg>/<component> --es extra_intent <serialized_intent>` or Drozer `app.activity.start`.

### Deep-Link / App-Link Hijacking

- **Deep links** (`<intent-filter>` with `android:scheme="myapp"`) are claimable by any app — no verification. Attacker app registers the same scheme and intercepts OAuth callbacks, password-reset tokens, or session tokens.
- **App links** (`android:autoVerify="true"`, `https://` scheme) require Digital Asset Links (`/.well-known/assetlinks.json`). Missing or misconfigured DAL falls back to chooser (claimable). Misconfigured `host` pattern (`*`) or wrong `sha256_cert_fingerprints` breaks verification silently.
- Test: disable DAL file on the server, install two apps with the same intent-filter, observe chooser — if shown, the link is hijackable.

### ContentProvider Path Traversal

- Exported `ContentProvider` with a file-serving `openFile()` implementation often resolves the supplied `Uri` path naively: `new File(rootDir, uri.getLastPathSegment())`. Supplying `../../../data/data/<pkg>/shared_prefs/creds.xml` reads arbitrary files within the app sandbox.
- Canonical pattern: `FileProvider` with an overly broad `<paths>` root (`<files-path path="." name="files"/>`) combined with a missing path-canonicalization check.
- Drozer: `app.provider.read content://<authority>/../../../data/data/<pkg>/shared_prefs/secret.xml`.

### Binder / AIDL Privilege Escalation

- Services bound via AIDL expose an interface; if `checkCallingPermission` / `enforceCallingPermission` is absent from sensitive methods, any app on the device can bind and call them.
- Sticky broadcasts (deprecated but present in legacy apps) can be spoofed: any app can send a sticky broadcast that overwrites the existing sticky for that action.

---

## Android — WebView Attacks

### WebView RCE via JavaScript Bridge

- `addJavascriptInterface(obj, "name")` exposes all `@JavascriptInterface`-annotated methods of `obj` to any page loaded in the WebView. If the WebView loads attacker-controlled content (via intent extras, deep-link redirect, or XSS in the loaded origin), the attacker calls `window.name.dangerousMethod()` → arbitrary Java execution → file read/write, `Runtime.exec()`, etc.
- Pre-API 17: ALL public methods of the bridged object were accessible (no annotation required) → trivially exploitable.

### WebView `file://` Access

- `setAllowFileAccessFromFileURLs(true)` / `setAllowUniversalAccessFromFileURLs(true)` lets a `file://` page send XHR to other `file://` paths — reads the entire app's private storage if a `file://` URL is loadable via intent.
- `setAllowFileAccess(false)` (API 30 default) does not prevent `file:///android_asset/` access.

### WebView SSL Pinning Bypass via `onReceivedSslError`

- Override that calls `handler.proceed()` unconditionally silences certificate errors — standard certificate MitM succeeds against the WebView even if the app pins elsewhere.

---

## iOS — URL Scheme & Universal Link Attacks

### Custom URL Scheme Hijacking

- Any app can register a custom URL scheme (`myapp://`). iOS presents a system chooser if multiple apps register the same scheme; the attacker's app can win. Use to intercept OAuth redirect tokens.
- No Digital Asset Links equivalent for custom schemes — mitigated only by using Universal Links.

### Universal Link Misconfiguration

- `apple-app-site-association` (AASA) must be served over HTTPS with `Content-Type: application/json` and without redirects from the exact path queried by CDNs.
- Common misconfigs: wildcard `"paths": ["*"]` expands attack surface; AASA served from CDN with wrong Content-Type falls back to custom scheme; `webcredentials` and `applinks` components confused.

### iOS URL-Scheme Redirect → Session Token Theft

- App opens a Safari/SFSafariViewController session for OAuth. After auth the provider redirects to `myapp://callback?code=...`. If the app does not validate the `state` parameter, an attacker app that intercepts the custom scheme redirect (or an attacker-controlled page in the same WebView session) steals the code.

---

## iOS — IPC & Extension Attacks

### App Groups / Shared Keychain Leakage

- Apps sharing the same App Group can read each other's `UserDefaults`, files, and (if entitlement is shared) Keychain items. A malicious app in the same developer team / enterprise distribution can read session tokens from a victim app's App Group container.

### XPC / NSXPCConnection Privilege Escalation

- XPC services run as daemons with higher privileges; if the `NSXPCInterface` methods lack proper input validation or caller identity checks (`xpc_connection_get_audit_token` + `SecTaskCopyValueForEntitlement`), a sandboxed process can trigger privileged operations.

### Pasteboard Sniffing

- `UIPasteboard.general` is accessible to all apps when the app is in the foreground on iOS < 16; on iOS 16+ apps must present a confirmation banner. Apps that write sensitive data (passwords, tokens) to the general pasteboard expose it to other apps.

---

## Hybrid Apps (React Native / Flutter / Cordova / Ionic)

### JavaScript-to-Native Bridge Injection

- React Native's `NativeModules`, Cordova plugins, and Flutter platform channels expose native APIs to JavaScript. If the WebView or JS bundle loads attacker-controlled JS (XSS, bundle tampering, hot-reload endpoints left open), the attacker calls privileged native methods: filesystem access, contacts, camera, crypto keystores.
- Hot-reload / Metro bundler left running in production builds allows remote JS replacement over the local network.

### Insecure `evaluateJavascript` / `runJavaScript`

- WKWebView's `evaluateJavaScript` called with attacker-influenced data executes arbitrary JS in the WebView context — path to bridge compromise.

---

## Mobile Backend API Attacks

### BOLA / IDOR via Mobile-Only Endpoints

- Mobile apps frequently use undocumented backend endpoints with weaker authorization than the web app — object IDs passed in JWT sub-claims, path parameters, or POST bodies that the server does not verify against the authenticated user.
- Technique: capture traffic via Burp/MITM proxy (install user certificate, or use `--proxy` with Flutter/RN debug builds), enumerate IDs by incrementing or fuzzing.

### Certificate Pinning Bypass

- Common bypass techniques: Frida (`SSL_CTX_set_verify` hook, OkHttp `CertificatePinner` hook), `objection` (`ios sslpinning disable` / `android sslpinning disable`), repack APK with Network Security Config `<trust-anchors>` permitting user CAs, patch `smali` to no-op the pinning check.
- Strong pinning (public-key pinning in native TLS stack, not OkHttp layer) requires `FRIDA_GADGET` injection or rooted device with Magisk + Frida server.

### JWT / Token Storage Weaknesses

- Android: tokens in `SharedPreferences` (world-readable on rooted device; accessible via backup if `allowBackup=true`), in `SQLiteDatabase` without encryption, or in logcat.
- iOS: tokens in `NSUserDefaults` (not encrypted, backed up to iCloud by default), in `plist` files in the Documents directory (iCloud backup), or logged via `NSLog` / `print`.
- Secure storage: Android Keystore-backed `EncryptedSharedPreferences`; iOS Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.

---

## Recon & Testing Approach

| Step | Tool / Command |
|------|---------------|
| APK static analysis | `apktool d app.apk` → decompile; `jadx-gui` for Java/Kotlin decompile |
| Manifest review | `aapt2 dump badging app.apk`; inspect `AndroidManifest.xml` for exported components, permissions, `debuggable`, `allowBackup` |
| IPA static analysis | `unzip app.ipa`; `class-dump` / `Hopper` for ObjC/Swift symbols; `otool -l` for linked libs |
| Traffic intercept (Android) | Burp + Android emulator with user CA, or `mitmproxy`; `adb shell settings put global http_proxy host:port` |
| Traffic intercept (iOS) | Burp + iOS device with profile; `objection ios sslpinning disable` for pinned apps |
| Dynamic (Android) | `objection explore` on rooted device / emulator; Frida scripts for hook injection |
| Dynamic (iOS) | `objection explore` on jailbroken device; Frida server via `Cydia` / `palera1n` |
| Deep-link testing | `adb shell am start -a android.intent.action.VIEW -d "myapp://path?param=value"` |
| ContentProvider enum | `drozer app.provider.info -a <pkg>`; `app.provider.read` / `app.provider.query` |

---

## Phase Integration

- **Phase L0 (Recency):** flag commits touching `AndroidManifest.xml`, `Info.plist`, WebView configuration, certificate-pinning logic, or exported component declarations.
- **Phase L1 (Recon):** identify platform (Android API level, iOS deployment target), exported component count, `allowBackup`, `debuggable`, network security config, deep-link scheme registrations.
- **Phase L3.5 (Sink Loading):** load `references/sinks/mobile.md` for Android/iOS sink audit; load this file for attack-technique routing.
- **Phase L4 (Taint):** trace intent extras / URL scheme parameters / IPC arguments through exported components to sensitive sinks (file open, `Runtime.exec`, `addJavascriptInterface` bridges, Keychain/Keystore write).
- **Phase L5 (PoC):** reproduce on emulator/device; for BOLA/token leakage, demonstrate with Burp replay; for bridge RCE, supply a minimal HTML/JS payload loaded by the WebView.
