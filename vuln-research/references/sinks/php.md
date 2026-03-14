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

**Dynamic inclusion:**
`include`, `include_once`, `require`, `require_once` with variable path

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
