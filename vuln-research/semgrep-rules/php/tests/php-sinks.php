<?php
// Scan sample for php-sinks.yaml (merged pack) — intentionally vulnerable. Do not deploy.
// Usage: semgrep --config semgrep-rules/php/php-sinks.yaml semgrep-rules/php/tests/php-sinks.php


// rce-direct-command-exec
system($_GET['cmd']);
exec($_POST['c']);
shell_exec($_REQUEST['x']);

// rce-backtick-operator
$out = `id $_GET[u]`;

// rce-eval-with-variable
eval($_POST['code']);

// rce-assert-string-arg
assert($_GET['expr']);

// rce-preg-replace-e-modifier
preg_replace('/.*/e', $_GET['r'], $subject);

// rce-create-function
$f = create_function('$x', $_GET['body']);

// rce-call-user-func-tainted-callable
call_user_func($_GET['fn'], 'arg');
call_user_func_array($_POST['fn'], []);

// rce-array-callback-tainted
array_map($_GET['cb'], [1, 2, 3]);
usort($arr, $_POST['cmp']);

// rce-handler-registration-tainted
register_shutdown_function($_GET['h']);
set_error_handler($_POST['h']);

// lfi-dynamic-include
include $_GET['page'];
require_once $_POST['mod'];

// stream-wrapper-attacker-reachable
$x = "php://input";
$y = "phar://upload.jpg/shell.php";

// iconv-cve-2024-2961-filter
$data = file_get_contents("php://filter/convert.iconv.UTF-8.ISO-2022-CN-EXT/resource=/etc/passwd");

// deserialization-unserialize-user-input
$obj = unserialize($_COOKIE['session']);

// phar-deserialization-trigger
file_exists($_GET['path']);

// sqli-concat-mysql
mysql_query("SELECT * FROM u WHERE id=" . $_GET['id']);
$db->query("SELECT * FROM u WHERE name='" . $_POST['n'] . "'");

// sqli-order-by-direct
$q = "SELECT * FROM t ORDER BY $_GET[col]";

// xss-echo-superglobal
echo $_GET['msg'];
print $_POST['name'];

// xss-short-echo-superglobal (intentional in template style)
?><div><?= $_GET['html'] ?></div><?php

// ssrf-curl-user-url
$ch = curl_init($_GET['url']);
curl_setopt($ch, CURLOPT_URL, $_POST['target']);

// ssrf-file-get-contents-user-url
$body = file_get_contents($_GET['url']);

// xxe-simplexml-load
$xml = simplexml_load_string($_POST['xml']);

// path-traversal-user-input
$content = file_get_contents("/var/data/" . $_GET['file']);

// type-juggling-magic-hash-compare
if (md5($_GET['p']) == "0e123456789012345678901234567890") {}

// type-juggling-strcmp-array
if (strcmp($_GET['pass'], $real) == 0) {}

// type-juggling-in-array-no-strict
if (in_array($_GET['role'], ['admin', 'user'])) {}

// crypto-md5-sha1-for-password
$hash = md5($password);

// crypto-mcrypt-deprecated
mcrypt_encrypt(MCRYPT_RIJNDAEL_128, $key, $data, MCRYPT_MODE_ECB);

// crypto-weak-rand-for-token
$token = md5(rand());

// crlf-header-user-input
header("Location: " . $_GET['next']);

// mail-fifth-param-user-controlled
mail($to, $sub, $msg, $hdr, $_POST['flags']);

// extract-superglobal
extract($_GET);

// parse-str-no-result-array
parse_str($_SERVER['QUERY_STRING']);

// upload-user-controlled-destination
move_uploaded_file($_FILES['f']['tmp_name'], "/uploads/" . $_FILES['f']['name']);

// ziparchive-extractto-no-validation
$zip->extractTo($target);

// info-disclosure-phpinfo
phpinfo();

// auth-loose-password-comparison
if ($_GET['password'] == $stored) {}

// disable-security-ini-set
ini_set('disable_functions', '');
putenv("LD_PRELOAD=/tmp/evil.so");


// ===========================================================================
// CATEGORY 1: SSRF — Additional sinks
// ===========================================================================

// ssrf-fsockopen-user-host
$fp = fsockopen($_GET['host'], 80);
$fp2 = pfsockopen($_POST['host'], 443);

// ssrf-stream-socket-client
$fp3 = stream_socket_client("tcp://" . $_GET['ip'] . ":6379");

// ssrf-guzzle-client-user-url
$client = new GuzzleHttp\Client();
$resp = $client->get($_GET['url']);
$resp2 = $client->post($_POST['target'], ['timeout' => 5]);

// ssrf-http-request-wrapper-functions
$body = http_get($_GET['url']);
$body2 = wp_remote_get($_POST['target']);
$resp3 = Requests::get($_GET['url']);

// ssrf-http-request-objects
$req = new Zend_Http_Client($_GET['url']);
$req->request();

// ===========================================================================
// CATEGORY 2: XXE — Additional sinks
// ===========================================================================

// xxe-xml-parse-expat
$parser = xml_parser_create();
xml_parse($parser, $_POST['xml']);
xml_parse_into_struct($parser, $_GET['data'], $vals);

// xxe-xmlreader-open-file
$reader = new XMLReader();
$reader->open($_GET['xml_path']);

// xxe-xsltprocessor-import
$proc = new XSLTProcessor();
$proc->importStylesheet(simplexml_load_string($_POST['xsl']));

// xxe-dom-load-html
$doc = new DOMDocument();
$doc->loadHTML($_POST['html']);
$doc2 = new DOMDocument();
$doc2->loadHTMLFile($_GET['path']);

// ===========================================================================
// CATEGORY 3: File Read — Additional sinks
// ===========================================================================

// file-read-highlight-source
highlight_file($_GET['file']);
show_source($_POST['path']);

// file-read-php-strip-whitespace
echo php_strip_whitespace($_GET['file']);

// file-read-parse-ini
$config = parse_ini_file($_GET['config']);

// file-read-spl-file-object
$file = new SplFileObject($_GET['path']);
$info = new SplFileInfo($_POST['file']);

// file-read-file-function
$lines = file($_GET['file']);

// file-read-gzfile
$lines2 = gzfile($_GET['gz']);
readgzfile($_POST['gz']);

// file-read-finfo-file
$f = new finfo(FILEINFO_MIME);
$mime = $f->file($_GET['file']);

// ===========================================================================
// CATEGORY 4: File Write — Additional sinks
// ===========================================================================

// file-write-file-put-contents
file_put_contents('/var/www/' . $_GET['path'], $_POST['data']);

// file-write-rename-copy-dest
rename('/tmp/up', '/var/www/' . $_GET['dest']);
copy('/tmp/up', $_POST['dest']);

// file-write-image-function
imagepng($img, $_GET['dest']);
imagejpeg($img, '/var/www/' . $_POST['path']);
imagegif($img, $_REQUEST['file']);

// file-write-iptcembed
iptcembed($iptc, $_GET['file']);

// file-write-unlink-deletion
unlink('/var/cache/' . $_GET['file']);

// file-write-touch-mkdir
mkdir('/var/www/' . $_GET['dir'], 0755);
touch($_POST['path']);

// ===========================================================================
// CATEGORY 5: FTP/SSH Sinks
// ===========================================================================

// ftp-path-traversal
ftp_get($conn, $_GET['local'], 'remote.txt', FTP_BINARY);
ftp_put($conn, '/remote/dest', $_GET['local'], FTP_BINARY);
ftp_nb_get($conn, $_POST['local'], 'file', FTP_BINARY);

// ssh-scp-path-traversal
ssh2_scp_recv($conn, '/remote/file', $_GET['local']);
ssh2_scp_send($conn, $_GET['local'], '/remote/dest');

// ssh-exec-command-injection
$stream = ssh2_exec($conn, $_GET['cmd']);

// ssh-connect-ssrf
ssh2_connect($_GET['host'], 22);

// ===========================================================================
// CATEGORY 6: Image Processing SSRF/LFI
// ===========================================================================

// image-create-from-user-path
$im1 = imagecreatefromgif($_GET['file']);
$im2 = imagecreatefromjpeg($_POST['img']);
$im3 = imagecreatefrompng($_GET['path']);
$im4 = imagecreatefromwebp($_REQUEST['src']);
$im5 = imagecreatefrombmp($_GET['tex']);
$im6 = imagecreatefromtga($_POST['tex']);
$im7 = imagecreatefromwbmp($_GET['icon']);
$im8 = imagecreatefromxbm($_GET['xbm']);
$im9 = imagecreatefromxpm($_POST['xpm']);

// ===========================================================================
// CATEGORY 7: Archive Extraction — Beyond Zip
// ===========================================================================

// archive-tar-extract
$tar = new Archive_Tar('backup.tar');
$tar->extract($_GET['dir']);

// archive-zip-get-entry
$zip->getFromName($_GET['entry']);
$zip->getStream($_POST['entry']);

// archive-phar-extract-to
$phar->extractTo($_GET['dir']);

// ===========================================================================
// CATEGORY 8: Header Injection / CRLF
// ===========================================================================

// crlf-setcookie-user-input
setcookie($_GET['name'], 'value');
setcookie('test', $_GET['value'], 0, '/', $_GET['domain']);
setrawcookie('token', $_POST['value']);

// crlf-header-no-exit-after-location
header("Location: " . $_GET['url']);
// No exit() - script continues

// ===========================================================================
// CATEGORY 9: Open Redirect
// ===========================================================================

// open-redirect-refresh-header
header("Refresh: 0; url=" . $_GET['url']);

// open-redirect-wp-redirect
wp_redirect($_GET['redirect_to']);

// open-redirect-laravel-redirect
return redirect()->to($_GET['url']);
return redirect()->away($_POST['ext_url']);

// open-redirect-symfony-redirect
return new RedirectResponse($_GET['url']);

// open-redirect-cakephp-redirect
$this->redirect($_GET['url']);
