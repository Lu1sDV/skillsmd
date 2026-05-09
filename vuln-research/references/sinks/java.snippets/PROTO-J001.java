URI uri = new URI(userUrl);      // "http://trusted.internal#@evil.com/"
uri.getHost(); // "trusted.internal"  → passes validation
URL url = new URL(userUrl);   // same URL
url.getHost();  // "evil.com"  → actual connection target
