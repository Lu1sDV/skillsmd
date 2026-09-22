<?php
// sanitizer_runner.php — target-agnostic sanitizer replay harness.
//
// Runs the REAL target sanitizer over the whole corpus, one PHP process per
// isolate. The isolate is a runtime-generated shim (NOT shipped with this
// engine) that `require`s the target's real sanitizer source and defines a
// function `sanitize(string $input): string`. This harness never mocks the
// sanitizer — it always calls the real target code via the isolate.
//
// Isolate contract (the shim must expose, after being required):
//   function sanitize(string $input): string { ...real target sanitizer... }
//
// Usage:
//   php sanitizer_runner.php --isolate <isolate.php> --corpus <corpus.json> --out <out.json>
//
// Output (out.json): a JSON array of [{id, html}] — one record per corpus row,
// where `html` is the REAL sanitized output. Errors per-row are captured so a
// single throwing payload does not abort the run; the oracle treats a row whose
// `html` is null + `error` set as a harness signal.

function fail(string $msg, int $code = 2): void {
    fwrite(STDERR, $msg . "\n");
    exit($code);
}

// --- arg parse (flag form only) ---
$opts = ['isolate' => null, 'corpus' => null, 'out' => null];
$argvRest = array_slice($argv, 1);
for ($i = 0; $i < count($argvRest); $i++) {
    $a = $argvRest[$i];
    switch ($a) {
        case '--isolate': $opts['isolate'] = $argvRest[++$i] ?? null; break;
        case '--corpus':  $opts['corpus']  = $argvRest[++$i] ?? null; break;
        case '--out':     $opts['out']     = $argvRest[++$i] ?? null; break;
        default: fail("unknown arg: $a");
    }
}
if ($opts['isolate'] === null || $opts['corpus'] === null || $opts['out'] === null) {
    fail("usage: sanitizer_runner.php --isolate <isolate.php> --corpus <corpus.json> --out <out.json>");
}
if (!is_file($opts['isolate'])) fail("isolate not found: {$opts['isolate']}");
if (!is_file($opts['corpus']))  fail("corpus not found: {$opts['corpus']}");

// --- load the isolate (REAL target sanitizer) ---
require $opts['isolate'];
if (!function_exists('sanitize')) {
    fail("isolate did not define sanitize(string): string — bad isolate contract", 3);
}

// --- stream the corpus ---
$corpus = json_decode(file_get_contents($opts['corpus']), true);
if (!is_array($corpus)) fail("bad corpus json");

$out = fopen($opts['out'], 'w');
if ($out === false) fail("cannot open out file: {$opts['out']}");
fwrite($out, "[");
$first = true;
$n = 0;
$errs = 0;
foreach ($corpus as $row) {
    $id = $row['id'] ?? null;
    $input = $row['input'] ?? '';
    $rec = ['id' => $id];
    try {
        $rec['html'] = sanitize((string)$input);
    } catch (\Throwable $e) {
        // Capture, never abort: the oracle reads `error` as an inconclusive signal.
        $rec['html'] = null;
        $rec['error'] = substr($e->getMessage(), 0, 200);
        $errs++;
    }
    fwrite($out, ($first ? "" : ",") . json_encode($rec, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
    $first = false;
    if ((++$n % 5000) === 0) fwrite(STDERR, "  sanitized $n\n");
}
fwrite($out, "]");
fclose($out);
fwrite(STDERR, "done: $n records ($errs errors) -> {$opts['out']}\n");
