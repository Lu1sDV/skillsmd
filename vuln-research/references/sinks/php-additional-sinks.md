# PHP Additional Sink Patterns — Beyond Current Coverage

> **Purpose:** Identify ALL PHP dangerous function patterns NOT yet covered by the
> then-current PHP rule pack. **Merged already:** these sinks are now rules inside
> `semgrep-rules/php/php-sinks.yaml` (439 rules, merged from the mega-pack + gap + additional
> packs; the merge ledger is in that file's header). This doc remains the human catalog for
> the pattern families — the mirror of the pack, per `semgrep-rules/README.md`.

**Current coverage** (already ruled, not duplicated here):
- SSRF: curl_setopt(CURLOPT_URL), curl_init(), file_get_contents(), fopen(), readfile(), get_headers(), copy(), SoapClient
- XXE: simplexml_load_string/file, DOMDocument::loadXML/load, SimpleXMLElement, XMLReader::xml
- Path traversal: file_get_contents/fopen/readfile/include/require with concat
- Zip slip: ZipArchive::extractTo, PharData::extractTo
- Header injection: header() with superglobals, mail() 5th param
- Open redirect: header("Location:") with $_GET/$_POST/$_REQUEST/$_SERVER
- RCE/command/callback/XSS/SQLi/type-juggling/deserialization/crypto/variable-manipulation

---

## 1. SSRF — Additional Sinks (10 new)

### 1.1 `fsockopen($hostname, ...)` — Raw TCP socket SSRF
- **Why dangerous:** Opens a raw TCP connection to any host:port. Attacker-controlled hostname reaches internal services (Redis, Memcached, MySQL unix socket, internal HTTP). Bypasses `allow_url_fopen=Off`.
- **Example:**
  ```php
  $fp = fsockopen($_GET['host'], $_GET['port']);
  fwrite($fp, "GET / HTTP/1.0\r\n\r\n");
  ```
- **CWE:** CWE-918
- **Confidence:** Confirmed

### 1.2 `pfsockopen($hostname, ...)` — Persistent raw socket SSRF
- **Why dangerous:** Same as fsockopen but persistent; connection re-used across requests.
- **Example:**
  ```php
  $fp = pfsockopen($_POST['host'], 80);
  ```
- **CWE:** CWE-918
- **Confidence:** Confirmed

### 1.3 `stream_socket_client($remote_socket, ...)` — TCP/TLS/Unix socket SSRF
- **Why dangerous:** More general than fsockopen; supports TLS and Unix domain sockets. Reaches internal services or local socket files.
- **Example:**
  ```php
  $fp = stream_socket_client("tcp://" . $_GET['ip'] . ":6379");
  ```
- **CWE:** CWE-918
- **Confidence:** Confirmed

### 1.4 `stream_context_create(...)` with `http` wrapper — Context-based SSRF
- **Why dangerous:** Creates an HTTP context with attacker-controlled options; when passed to file_get_contents/fopen, controls the remote request (method, headers, proxy). Enables SSRF even when URL is semi-fixed.
- **Example:**
  ```php
  $ctx = stream_context_create(['http' => ['proxy' => $_GET['proxy'], 'header' => "X-Auth: bypass\r\n"]]);
  echo file_get_contents('http://internal/admin', false, $ctx);
  ```
- **CWE:** CWE-918
- **Confidence:** Confirmed

### 1.5 GuzzleHttp\Client with user URL
- **Why dangerous:** Dominant PHP HTTP client (used by Composer, Laravel, Drupal, WordPress plugins). `$client->get($user_url)` sends attacker-controlled HTTP requests to internal services.
- **Example:**
  ```php
  $client = new GuzzleHttp\Client();
  $resp = $client->get($_GET['url']);  // SSRF to internal metadata
  ```
- **CWE:** CWE-918
- **Confidence:** Confirmed

### 1.6 `Requests::get()` / `Requests::post()` — WordPress HTTP API (if standalone library)
- **Why dangerous:** Requests library (used by WordPress) sends HTTP requests. User-controlled URL = SSRF.
- **Example:**
  ```php
  $response = Requests::get($_GET['url']);
  ```
- **CWE:** CWE-918
- **Confidence:** Confirmed

### 1.7 `wp_remote_get()` / `wp_remote_post()` — WordPress HTTP API
- **Why dangerous:** WordPress's native HTTP API wrapper. `wp_remote_get($user_url)` fetches attacker-controlled URL — SSRF to internal services from any WordPress plugin/theme.
- **Example:**
  ```php
  $response = wp_remote_get($_GET['url']);
  ```
- **CWE:** CWE-918
- **Confidence:** Confirmed

### 1.8 `Zend_Http_Client::request()` — Zend Framework 1
- **Why dangerous:** Legacy framework HTTP client. User-controlled URI reaches internal.
- **Example:**
  ```php
  $client = new Zend_Http_Client($_GET['url']);
  $response = $client->request();
  ```
- **CWE:** CWE-918
- **Confidence:** Confirmed

### 1.9 `HTTP_Request2::send()` — PEAR HTTP_Request2
- **Why dangerous:** PEAR package for HTTP. User URL = SSRF.
- **Example:**
  ```php
  $req = new HTTP_Request2($_GET['url']);
  $response = $req->send();
  ```
- **CWE:** CWE-918
- **Confidence:** Confirmed

### 1.10 `http_get()` / `http_post()` / `http_request()` — PECL pecl_http (ext-http)
- **Why dangerous:** Unmaintained PECL extension. Direct HTTP request functions with user URL.
- **Example:**
  ```php
  $body = http_get($_GET['url']);
  ```
- **CWE:** CWE-918
- **Confidence:** Confirmed

---

## 2. XXE — Additional Sinks (8 new)

### 2.1 `xml_parse($parser, $data)` — Expat XML parser XXE
- **Why dangerous:** The Expat-based SAX parser (`xml_parser_create()`) resolves external entities by default when resource loading is not disabled. Attacker-controlled XML can read files via entities.
- **Example:**
  ```php
  $parser = xml_parser_create();
  xml_parser_set_option($parser, XML_OPTION_SKIP_WHITE, 1);
  xml_parse($parser, $_POST['xml']);  // XXE if entity loader not disabled
  ```
- **CWE:** CWE-611
- **Confidence:** Confirmed

### 2.2 `xml_parse_into_struct($parser, $data, ...)` — Expat XML struct XXE
- **Why dangerous:** Same XML parser as xml_parse; splits XML into array structure. Attacker-controlled XML can read files via external entities.
- **Example:**
  ```php
  $parser = xml_parser_create();
  xml_parse_into_struct($parser, $_GET['xml'], $vals, $index);
  ```
- **CWE:** CWE-611
- **Confidence:** Confirmed

### 2.3 `XMLReader::open($uri)` — XMLReader file/URL open XXE
- **Why dangerous:** Opens XML from a file or URL path. If user controls the path, they can point to a crafted XML file. Also, the XML at that path can contain entity declarations that read local files.
- **Example:**
  ```php
  $reader = new XMLReader();
  $reader->open($_GET['xml_path']);  // XXE from remote/crafted XML
  ```
- **CWE:** CWE-611
- **Confidence:** Confirmed

### 2.4 `XSLTProcessor::importStylesheet()` — XSLT XXE
- **Why dangerous:** XSLT stylesheets can contain entity declarations. Importing a user-controlled stylesheet (or from user-controlled path) allows XXE via `<xsl:value-of select="document('/etc/passwd')"/>`.
- **Example:**
  ```php
  $proc = new XSLTProcessor();
  $xsl = new DOMDocument();
  $xsl->loadXML($_POST['xsl']);
  $proc->importStylesheet($xsl);      // XXE via entity in XSL
  echo $proc->transformToXML($doc);
  ```
- **CWE:** CWE-611
- **Confidence:** Confirmed

### 2.5 `XSLTProcessor::transformToXML()` / `::transformToDoc()` — XSLT execution XXE
- **Why dangerous:** Triggers XSLT transformation; if the stylesheet was imported with entities enabled, this is the execution point.
- **Example:**
  ```php
  $result = $proc->transformToXML(new DOMDocument());  // trigger XXE from tainted stylesheet
  ```
- **CWE:** CWE-611
- **Confidence:** Confirmed

### 2.6 `DOMDocument::loadHTML($source)` — HTML+Entity XXE
- **Why dangerous:** PHP's `loadHTML` resolves HTML entities, including XML external entities in DOCTYPE. User-controlled HTML can contain `<!ENTITY xxe SYSTEM "file:///etc/passwd">`.
- **Example:**
  ```php
  $doc = new DOMDocument();
  $doc->loadHTML($_POST['html']);  // XXE via DOCTYPE entity in HTML
  ```
- **CWE:** CWE-611
- **Confidence:** Confirmed

### 2.7 `DOMDocument::loadHTMLFile($uri)` — HTML file XXE
- **Why dangerous:** Same as loadHTML but reads from path/URL. Combined with user-controlled path = XXE.
- **Example:**
  ```php
  $doc = new DOMDocument();
  $doc->loadHTMLFile($_GET['path']);  // XXE
  ```
- **CWE:** CWE-611
- **Confidence:** Confirmed

### 2.8 `xml_set_external_entity_ref_handler()` — Custom entity handler (XXE sink + info leak)
- **Why dangerous:** Registers a callback that fires when external entities are resolved. If not hardening before this, the entity is already resolved. Can also be used as an exfiltration channel if attacker controls the handler.
- **Example:**
  ```php
  xml_set_external_entity_ref_handler($parser, "evil_handler");
  // If handler is attacker-controlled = RCE; if entity reads files = XXE still happens
  ```
- **CWE:** CWE-611
- **Confidence:** Likely

---

## 3. File Read — Additional Sinks (12 new)

### 3.1 `highlight_file($filename)` / `show_source($filename)` — Source disclosure + file read
- **Why dangerous:** Reads and syntax-highlights any file. User-controlled path reads arbitrary files. If allow_url_fopen=On, also SSRF.
- **Example:**
  ```php
  highlight_file($_GET['file']);  // reads /etc/passwd, db config, etc.
  ```
- **CWE:** CWE-200 / CWE-22
- **Confidence:** Confirmed

### 3.2 `php_strip_whitespace($filename)` — Source read
- **Why dangerous:** Reads file, strips comments/whitespace. User path = arbitrary file read.
- **Example:**
  ```php
  echo php_strip_whitespace($_GET['file']);  // reads any file
  ```
- **CWE:** CWE-200 / CWE-22
- **Confidence:** Confirmed

### 3.3 `get_meta_tags($filename, ...)` — URL metadata fetch
- **Why dangerous:** Extracts meta tags from a URL/path. User URL = SSRF. User path = file read.
- **Example:**
  ```php
  $tags = get_meta_tags($_GET['url']);  // SSRF + file read
  ```
- **CWE:** CWE-918 / CWE-22
- **Confidence:** Confirmed

### 3.4 `parse_ini_file($filename, ...)` — INI file read
- **Why dangerous:** Reads and parses INI files. User-controlled path reads arbitrary files (configs, .env, /etc/passwd try as INI).
- **Example:**
  ```php
  $config = parse_ini_file($_GET['file']);  // reads arbitrary INI-formatted files
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 3.5 `parse_ini_string($ini, ...)` with user input
- **Why dangerous:** Parses INI-formatted string; if user provides the string, can leak info via error messages (less critical but can be used in LFI chains).
- **Example:**
  ```php
  $config = parse_ini_string($_POST['ini_data']);  // user-controlled parser input
  ```
- **CWE:** CWE-20
- **Confidence:** Likely

### 3.6 `SplFileObject::__construct($filename)` — SPL file read
- **Why dangerous:** Creates an SPL file object for any path. Can iterate lines, read via fread, fgets, fpassthru. User path = file read + phar deserialization trigger.
- **Example:**
  ```php
  $file = new SplFileObject($_GET['path']);
  while (!$file->eof()) echo $file->fgets();  // reads any file
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 3.7 `SplFileObject::current()` / `SplFileObject::fgets()` (via user-path object)
- **Why dangerous:** If an SplFileObject was created with a user-controlled path, these methods read file content.
- **Example:**
  ```php
  $file = new SplFileObject($_GET['file']);
  echo $file->current();  // line reads via tainted path
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 3.8 `SplFileInfo::openFile($mode)` — SPL file info open
- **Why dangerous:** Opens a file through SplFileInfo. User-controlled path leads to arbitrary file read.
- **Example:**
  ```php
  $info = new SplFileInfo($_GET['path']);
  $file = $info->openFile('r');  // reads any file
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 3.9 `file($filename, ...)` — File to array read
- **Why dangerous:** Reads entire file into an array (one line per element). User path = arbitrary file read + phar deserialization.
- **Example:**
  ```php
  $lines = file($_GET['file']);  // reads any file
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 3.10 `gzfile($filename)` — Gzip file read
- **Why dangerous:** Reads gzip-compressed file and decompresses. User path reads any file (plain files return single element, php:// wrappers work).
- **Example:**
  ```php
  $lines = gzfile($_GET['file']);  // reads compressed or plain files
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 3.11 `readgzfile($filename)` — Gzip file read and output
- **Why dangerous:** Like readfile but for gzip. User path = arbitrary file read with SSRF.
- **Example:**
  ```php
  readgzfile($_GET['file']);  // reads and outputs any file
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 3.12 `finfo::file($filename)` — File info/magic read
- **Why dangerous:** Reads file magic bytes. With user-controlled path, triggers phar deserialization and can be used in file read primitives. Also SSRF if allow_url_fopen.
- **Example:**
  ```php
  $finfo = new finfo(FILEINFO_MIME);
  echo $finfo->file($_GET['file']);  // phar deser trigger + SSRF
  ```
- **CWE:** CWE-22 / CWE-502
- **Confidence:** Confirmed

---

## 4. File Write — Additional Sinks (14 new)

### 4.1 `fwrite($handle, $data)` / `fputs($handle, $data)` with user-controlled path
- **Why dangerous:** When the file handle was opened with a user-controlled path (via fopen with user path), writes arbitrary content to any writable path. Path traversal + arbitrary write.
- **Example:**
  ```php
  $fp = fopen('/var/www/' . $_GET['path'], 'w');
  fwrite($fp, '<?php system($_GET["c"]); ?>');  // arbitrary file write
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 4.2 `file_put_contents($filename, $data)` with user path
- **Why dangerous:** Writes data to user-controlled path. Direct arbitrary file write to any writable location (web root for PHP shell, config overwrite, cron.d, .ssh/authorized_keys).
- **Example:**
  ```php
  file_put_contents('/var/www/' . $_GET['path'], $_POST['data']);  // arbitrary write
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 4.3 `rename($oldname, $newname)` with user path
- **Why dangerous:** Rename/move files to attacker-controlled paths. Write to web root, overwrite config files.
- **Example:**
  ```php
  rename('/tmp/upload', '/var/www/' . $_GET['dest']);  // move to arbitrary location
  ```
- **CWE:** CWE-22 / CWE-73
- **Confidence:** Confirmed

### 4.4 `copy($source, $dest)` with user destination path
- **Why dangerous:** When dest is user-controlled, writes arbitrary uploaded content to any writable path. Source covered in SSRF, dest is a write sink.
- **Example:**
  ```php
  copy('/tmp/upload', '/var/www/' . $_GET['dest']);  // arbitrary write
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 4.5 `imagepng($image, $dest)` — Image write to user path
- **Why dangerous:** Writes PNG image to user-controlled path. Can embed PHP code in image metadata or pixel data, write to web root as shell.
- **Example:**
  ```php
  imagepng($img, '/var/www/' . $_GET['path']);  // write image to arbitrary path
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 4.6 `imagejpeg($image, $dest)` — JPEG write to user path
- **Why dangerous:** Same as imagepng; writes JPEG to user-controlled path. Image-with-PHP-shell technique.
- **Example:**
  ```php
  imagejpeg($img, $_GET['dest']);  // arbitrary JPEG write
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 4.7 `imagegif($image, $dest)` — GIF write to user path
- **Why dangerous:** Same as above. Destination path = arbitrary file write (with GIF content).
- **Example:**
  ```php
  imagegif($img, $_GET['dest']);  // arbitrary GIF write
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 4.8 `imagewbmp($image, $dest)` / `image2wbmp($image, $dest)` — WBMP write
- **Why dangerous:** Writes WBMP image format to user-controlled path.
- **Example:**
  ```php
  imagewbmp($img, $_GET['dest']);  // arbitrary WBMP write
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 4.9 `imagegd($image, $dest)` / `imagegd2($image, $dest)` — GD image format write
- **Why dangerous:** Writes GD/GD2 image format to user-controlled path.
- **Example:**
  ```php
  imagegd2($img, '/var/www/' . $_GET['path']);  // arbitrary GD2 file write
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 4.10 `imagexbm($image, $dest)` — XBM write
- **Why dangerous:** Writes XBM (X BitMap) format to user-controlled path.
- **Example:**
  ```php
  imagexbm($img, $_GET['dest']);  // arbitrary XBM write
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 4.11 `iptcembed($iptcdata, $filename, $spool)` — IPTC metadata embed
- **Why dangerous:** Writes IPTC metadata into image file specified by user-controlled path. Can overwrite files in place.
- **Example:**
  ```php
  iptcembed($iptc, '/var/www/' . $_GET['path']);  // overwrite/modify arbitrary image files
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 4.12 `mkdir($pathname, ...)` with user path
- **Why dangerous:** Creates directories at user-controlled paths. Can be used to create `.ssh/`, create cron directories, etc.
- **Example:**
  ```php
  mkdir('/var/www/' . $_GET['dir']);  // directory creation at arbitrary location
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 4.13 `unlink($filename)` with user path — Arbitrary file deletion
- **Why dangerous:** Deletes any file the web user can write. Delete config files, .htaccess, index.php, lock files.
- **Example:**
  ```php
  unlink('/var/www/config/' . $_GET['file']);  // arbitrary file deletion
  ```
- **CWE:** CWE-22 / CWE-73
- **Confidence:** Confirmed

### 4.14 `touch($filename, ...)` with user path
- **Why dangerous:** Creates or modifies timestamps of any file. Can create empty files at arbitrary paths.
- **Example:**
  ```php
  touch('/var/www/' . $_GET['path']);  // create empty file at arbitrary path
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

---

## 5. FTP/SSH Sinks (7 new)

### 5.1 `ftp_get($ftp_stream, $local, $remote, ...)` — FTP file download
- **Why dangerous:** Downloads remote FTP file to local path. If remote path is user-controlled, reads arbitrary files from FTP server. If local path is user-controlled, writes to arbitrary location.
- **Example:**
  ```php
  ftp_get($conn, '/var/www/' . $_GET['dest'], 'config.php', FTP_BINARY);  // arbitrary file download
  ```
- **CWE:** CWE-22 / CWE-73
- **Confidence:** Confirmed

### 5.2 `ftp_put($ftp_stream, $remote, $local, ...)` — FTP file upload
- **Why dangerous:** Uploads local file to FTP server. If local path is user-controlled, leaks arbitrary local files.
- **Example:**
  ```php
  ftp_put($conn, '/remote/config.php', $_GET['local_file'], FTP_BINARY);  // upload arbitrary file
  ```
- **CWE:** CWE-200 / CWE-22
- **Confidence:** Confirmed

### 5.3 `ftp_nb_get()` / `ftp_nb_put()` — Non-blocking FTP file transfer
- **Why dangerous:** Non-blocking variants of ftp_get/ftp_put. Same risks.
- **Example:**
  ```php
  ftp_nb_get($conn, $_GET['local'], 'config.php', FTP_BINARY);  // arbitrary local write
  ```
- **CWE:** CWE-22 / CWE-73
- **Confidence:** Confirmed

### 5.4 `ssh2_scp_recv($conn, $remote, $local)` — SCP file download (read)
- **Why dangerous:** Downloads files from SSH server via SCP. If local path is user-controlled, writes to arbitrary location.
- **Example:**
  ```php
  ssh2_scp_recv($conn, '/remote/secret.txt', '/var/www/' . $_GET['dest']);  // arbitrary write
  ```
- **CWE:** CWE-22 / CWE-73
- **Confidence:** Confirmed

### 5.5 `ssh2_scp_send($conn, $local, $remote)` — SCP file upload (write)
- **Why dangerous:** Uploads local file to SSH server. If local path is user-controlled, exfiltrates arbitrary files. If remote path is user-controlled, writes arbitrary remote files.
- **Example:**
  ```php
  ssh2_scp_send($conn, $_GET['local'], '/remote/upload.txt');  // exfiltrate arbitrary file
  ```
- **CWE:** CWE-200 / CWE-22
- **Confidence:** Confirmed

### 5.6 `ssh2_exec($conn, $command)` — SSH remote command execution
- **Why dangerous:** Executes command on SSH server. User-controlled command = RCE on remote host.
- **Example:**
  ```php
  $stream = ssh2_exec($conn, $_GET['cmd']);  // RCE on remote SSH host
  ```
- **CWE:** CWE-77 / CWE-78
- **Confidence:** Confirmed

### 5.7 `ssh2_connect($host, ...)` — SSRF via SSH connection
- **Why dangerous:** Connects to arbitrary SSH server. User-controlled host/port = SSRF to internal SSH services.
- **Example:**
  ```php
  ssh2_connect($_GET['host'], 22);  // SSRF to internal SSH services
  ```
- **CWE:** CWE-918
- **Confidence:** Confirmed

---

## 6. Image Processing SSRF/LFI Sinks (9 new)

### 6.1 `imagecreatefromgif($filename)` — GIF image load SSRF/LFI
- **Why dangerous:** Opens GIF image from path/URL. User path = LFI + phar deserialization. User URL = SSRF.
- **Example:**
  ```php
  $im = imagecreatefromgif($_GET['file']);  // SSRF if URL, LFI if path, phar if phar://
  ```
- **CWE:** CWE-918 / CWE-22
- **Confidence:** Confirmed

### 6.2 `imagecreatefromjpeg($filename)` — JPEG image load
- **Why dangerous:** Same as above.
- **Example:**
  ```php
  $im = imagecreatefromjpeg($_GET['img']);  // SSRF + LFI + phar deser
  ```
- **CWE:** CWE-918 / CWE-22
- **Confidence:** Confirmed

### 6.3 `imagecreatefrompng($filename)` — PNG image load
- **Why dangerous:** Same as above.
- **Example:**
  ```php
  $im = imagecreatefrompng($_POST['path']);  // SSRF + LFI + phar deser
  ```
- **CWE:** CWE-918 / CWE-22
- **Confidence:** Confirmed

### 6.4 `imagecreatefromwebp($filename)` — WebP image load
- **Why dangerous:** Same; WebP is now common.
- **Example:**
  ```php
  $im = imagecreatefromwebp($_GET['file']);  // SSRF + LFI + phar deser
  ```
- **CWE:** CWE-918 / CWE-22
- **Confidence:** Confirmed

### 6.5 `imagecreatefromwbmp($filename)` — WBMP image load
- **Why dangerous:** Same.
- **Example:**
  ```php
  $im = imagecreatefromwbmp($_GET['src']);  // SSRF + LFI
  ```
- **CWE:** CWE-918 / CWE-22
- **Confidence:** Confirmed

### 6.6 `imagecreatefromxbm($filename)` — XBM image load
- **Why dangerous:** Same.
- **Example:**
  ```php
  $im = imagecreatefromxbm($_GET['file']);  // SSRF + LFI
  ```
- **CWE:** CWE-918 / CWE-22
- **Confidence:** Confirmed

### 6.7 `imagecreatefromxpm($filename)` — XPM image load
- **Why dangerous:** Same.
- **Example:**
  ```php
  $im = imagecreatefromxpm($_GET['icon']);  // SSRF + LFI
  ```
- **CWE:** CWE-918 / CWE-22
- **Confidence:** Confirmed

### 6.8 `imagecreatefrombmp($filename)` — BMP image load (PHP >= 7.2)
- **Why dangerous:** Same. BMP support added in PHP 7.2.
- **Example:**
  ```php
  $im = imagecreatefrombmp($_GET['file']);  // SSRF + LFI
  ```
- **CWE:** CWE-918 / CWE-22
- **Confidence:** Confirmed

### 6.9 `imagecreatefromtga($filename)` — TGA image load (PHP >= 7.4)
- **Why dangerous:** Same. TGA support added in PHP 7.4.
- **Example:**
  ```php
  $im = imagecreatefromtga($_GET['tex']);  // SSRF + LFI
  ```
- **CWE:** CWE-918 / CWE-22
- **Confidence:** Confirmed

---

## 7. Archive Extraction — Beyond Zip (5 new)

### 7.1 `PclZip::extract()` — PclZip library
- **Why dangerous:** PclZip (bundled with many CMS/applications) extracts zip entries without path validation. `../../shell.php` in zip lands outside target dir.
- **Example:**
  ```php
  $archive = new PclZip($_GET['zip']);
  $archive->extract(PCLZIP_OPT_PATH, '/var/www/uploads/');  // zip slip
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 7.2 `Archive_Tar::extract()` — PEAR Archive_Tar
- **Why dangerous:** PEAR Archive_Tar extracts tar/zip files. Entry paths not validated against target directory.
- **Example:**
  ```php
  $tar = new Archive_Tar($_GET['archive']);
  $tar->extract('/var/www/extract/');  // tar slip
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 7.3 `ZipArchive::getFromName($entryname)` — Zip entry read by name
- **Why dangerous:** Reads specific entry from zip by name. If entry name is user-controlled and contains `../`, reads files outside extraction target. Also path traversal in entry name.
- **Example:**
  ```php
  $zip = new ZipArchive();
  $zip->open('backup.zip');
  $data = $zip->getFromName($_GET['entry']);  // entry name traversal
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 7.4 `ZipArchive::getStream($entryname)` — Zip entry stream
- **Why dangerous:** Returns a stream handle for a zip entry by name. User-controlled entry name with `../` bypasses intended extraction boundaries.
- **Example:**
  ```php
  $stream = $zip->getStream($_GET['entry']);  // entry name traversal
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 7.5 `Phar::extractTo($dest)` — Phar extraction path traversal
- **Why dangerous:** Phar archive extraction (different from PharData — used for executable phars). Same zip/tar slip risk.
- **Example:**
  ```php
  $phar = new Phar('update.phar');
  $phar->extractTo('/var/www/' . $_GET['dir']);  // traversal if dir contains ..
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

---

## 8. Header Injection / CRLF — Beyond Current Rules (5 new)

### 8.1 `setcookie($name, ...)` with user input in name/value/path/domain
- **Why dangerous:** User-controlled cookie name or value can inject cookie path/domain attributes via CRLF (though modern PHP blocks raw CRLF in name, the value/path/domain can be manipulated). Cookie injection leads to session fixation, XSS, or cookie tossing.
- **Example:**
  ```php
  setcookie($_GET['name'], 'value', 0, '/');  // arbitrary cookie name injection
  setcookie('token', $_GET['val'], 0, '/', $_GET['domain']);  // domain injection
  ```
- **CWE:** CWE-93 / CWE-79
- **Confidence:** Confirmed

### 8.2 `setrawcookie($name, $value, ...)` with user input
- **Why dangerous:** Same as setcookie but value is NOT URL-encoded. User-controlled raw value can inject arbitrary Set-Cookie header content including `\r\n` for header injection (on PHP < 5.1.2 or specific builds). Cookie prefix injection (`__Host-`, `__Secure-` bypass).
- **Example:**
  ```php
  setrawcookie('token', $_GET['value']);  // raw cookie value injection
  ```
- **CWE:** CWE-93
- **Confidence:** Confirmed

### 8.3 `header()` with CRLF in value (legacy/PHP < 5.1.2)
- **Why dangerous:** While modern PHP (>=5.1.2) blocks CRLF in header values, legacy codebases running older PHP are vulnerable to full response splitting. Additionally, single `\n` without `\r` sometimes passes filters on misconfigured builds.
- **Example:**
  ```php
  header("X-Custom: " . $_GET['val']);  // CRLF injection if PHP < 5.1.2 or misconfig
  ```
- **CWE:** CWE-93
- **Confidence:** Likely (legacy)

### 8.4 `session_set_cookie_params()` with user input
- **Why dangerous:** Sets the session cookie parameters (lifetime, path, domain, secure, httponly). User-controlled domain allows cross-domain session cookie injection.
- **Example:**
  ```php
  session_set_cookie_params(3600, '/', $_GET['domain']);  // session cookie domain injection
  ```
- **CWE:** CWE-93 / CWE-784
- **Confidence:** Likely

### 8.5 `session_name($name)` with user input
- **Why dangerous:** Sets session name (cookie name for session ID). User-controlled name can inject cookie attributes or perform session fixation.
- **Example:**
  ```php
  session_name($_GET['name']);  // session cookie name injection
  ```
- **CWE:** CWE-93
- **Confidence:** Likely

---

## 9. Open Redirect — Additional Patterns (7 new)

### 9.1 `header("Location: ...")` without `exit`/`die()` — Redirect bypass
- **Why dangerous:** The existing rule catches Location with superglobals, but NOT the missing exit/die pattern. Apache follows Location header but continues execution — attacker-controlled page content served to redirect-following bots/proxies, or auth bypass.
- **Example:**
  ```php
  header("Location: " . $_GET['url']);
  // No exit() here — script continues, serves XSS or sensitive content after redirect
  ```
- **CWE:** CWE-601 / CWE-698
- **Confidence:** Confirmed

### 9.2 `header("Refresh: ...")` with user URL — Meta-refresh open redirect
- **Why dangerous:** The `Refresh` header redirects after N seconds. User-controlled URL in the refresh targets = open redirect. Less commonly checked than Location.
- **Example:**
  ```php
  header("Refresh: 0; url=" . $_GET['url']);  // open redirect via Refresh
  ```
- **CWE:** CWE-601
- **Confidence:** Confirmed

### 9.3 `wp_redirect($url)` — WordPress open redirect
- **Why dangerous:** WordPress's `wp_redirect()` sends a Location header. If URL not validated, open redirect. WordPress has `wp_safe_redirect()` but many themes/plugins use `wp_redirect()` with user input.
- **Example:**
  ```php
  wp_redirect($_GET['redirect_to']);  // open redirect
  ```
- **CWE:** CWE-601
- **Confidence:** Confirmed

### 9.4 Symfony `RedirectResponse` with user URL
- **Why dangerous:** Symfony's `RedirectResponse` sends Location header. User-controlled URL = open redirect.
- **Example:**
  ```php
  return new RedirectResponse($_GET['url']);  // open redirect
  ```
- **CWE:** CWE-601
- **Confidence:** Confirmed

### 9.5 Laravel `redirect()->to()` / `redirect()->away()` — Laravel open redirect
- **Why dangerous:** Laravel has `redirect()->to($path)` for internal paths and `redirect()->away($url)` for external. User URL = open redirect. `->to()` with user URL that contains `://` bypasses internal-only check.
- **Example:**
  ```php
  return redirect()->to($_GET['url']);  // open redirect (bypass if url has scheme)
  return redirect()->away($_GET['ext_url']);  // explicit external redirect
  ```
- **CWE:** CWE-601
- **Confidence:** Confirmed

### 9.6 Zend Framework / Laminas `$this->redirect()` — Zend redirect
- **Why dangerous:** Old Zend Framework (used in Magento 1/2) redirect controller plugin. User URL = open redirect.
- **Example:**
  ```php
  return $this->redirect()->toUrl($_GET['url']);  // open redirect
  ```
- **CWE:** CWE-601
- **Confidence:** Confirmed

### 9.7 CakePHP `$this->redirect($url)` — CakePHP open redirect
- **Why dangerous:** CakePHP's redirect method sends Location header with user URL.
- **Example:**
  ```php
  return $this->redirect($_GET['url']);  // open redirect
  ```
- **CWE:** CWE-601
- **Confidence:** Confirmed

---

## 10. Bonus: Path Traversal — Expanded Sinks for concat patterns (5 extra)

### 10.1 Path traversal via `file_put_contents` with concat
- **Why dangerous:** Writes arbitrary data to user-controlled path via concatenation.
- **Example:**
  ```php
  file_put_contents('/var/www/' . $_GET['path'], $_POST['data']);
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 10.2 Path traversal via `rename`, `copy` (dest) with concat
- **Why dangerous:** Rename or copy to user-controlled destination path.
- **Example:**
  ```php
  rename('/tmp/up', '/var/www/' . $_GET['dest']);
  copy('/tmp/up', '/var/www/' . $_GET['dest']);
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 10.3 Path traversal via `unlink` with concat
- **Why dangerous:** Deletes files at user-controlled paths.
- **Example:**
  ```php
  unlink('/var/www/cache/' . $_GET['file']);
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 10.4 Path traversal via `SplFileObject` with concat
- **Why dangerous:** Creates SPL file object at user-controlled path.
- **Example:**
  ```php
  $f = new SplFileObject('/var/data/' . $_GET['file']);
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

### 10.5 Path traversal via `highlight_file` / `show_source` with concat
- **Why dangerous:** Reads and highlights files at user-controlled paths.
- **Example:**
  ```php
  highlight_file('/var/www/templates/' . $_GET['file']);
  ```
- **CWE:** CWE-22
- **Confidence:** Confirmed

---

## Summary Statistics

| Category | New Sinks |
|----------|-----------|
| 1. SSRF (additional) | 10 |
| 2. XXE (additional) | 8 |
| 3. File read (additional) | 12 |
| 4. File write (additional) | 14 |
| 5. FTP/SSH | 7 |
| 6. Image processing SSRF/LFI | 9 |
| 7. Archive extraction (beyond zip) | 5 |
| 8. Header injection / CRLF | 5 |
| 9. Open redirect | 7 |
| 10. Bonus: Path traversal expanded | 5 |
| **Total** | **82** |

## Key CWE Mappings
- CWE-22: Path Traversal (most file operations)
- CWE-73: External Control of File Name or Path
- CWE-77/78: Command Injection (SSH exec)
- CWE-93: CRLF Injection / HTTP Response Splitting
- CWE-200: Exposure of Sensitive Information
- CWE-434: Unrestricted File Upload
- CWE-502: Deserialization of Untrusted Data (phar triggers)
- CWE-601: Open Redirect
- CWE-611: Improper Restriction of XML External Entity Reference
- CWE-698: Execution After Redirect
- CWE-784: Reliance on Cookies without Validation
- CWE-918: Server-Side Request Forgery
