# PHP Framework-Specific Security Sinks

This document catalogs dangerous function/pattern usage specific to PHP frameworks (Laravel, Symfony, WordPress, Drupal, CodeIgniter, Yii, CakePHP, and generic template engines). These are **framework-level** sinks beyond the core PHP sinks catalogued in `php.md`.

**Target:** Semgrep rules, SAST signatures, code review checklists.

---

## 1. Laravel Sinks

### 1.1 SQL Injection — Raw Query Methods

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 1 | `DB::raw($userInput)` | Inserts raw SQL into a query builder chain. Any user input in the expression is unescaped. The Laravel docs explicitly warn: "Laravel cannot guarantee that any query using raw expressions is protected against SQL injection." | CWE-89 | **Confirmed** |
| 2 | `$q->whereRaw($userInput)` | Raw WHERE clause — no parameter binding for the expression string itself | CWE-89 | **Confirmed** |
| 3 | `$q->selectRaw($userInput)` | Raw SELECT column list — user-controlled column expression | CWE-89 | **Confirmed** |
| 4 | `$q->havingRaw($userInput)` | Raw HAVING clause — user-controlled aggregate filter | CWE-89 | **Confirmed** |
| 5 | `$q->orderByRaw($userInput)` | Raw ORDER BY — user-controlled sort expression | CWE-89 | **Confirmed** |
| 6 | `$q->groupByRaw($userInput)` | Raw GROUP BY — user-controlled grouping expression | CWE-89 | **Confirmed** |
| 7 | `DB::statement($userInput)` | Executes arbitrary SQL with no parameterization at all | CWE-89 | **Confirmed** |
| 8 | `DB::unprepared($userInput)` | Executes SQL **without** any preparation or event dispatching — no query logging, no protection | CWE-89 | **Confirmed** |
| 9 | `DB::select($userInput)` | Raw `SELECT` query execution directly from user input | CWE-89 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: Raw expressions with user input
DB::table('users')
    ->whereRaw("name = '" . request('name') . "'")
    ->get();

DB::table('users')
    ->selectRaw("name, email, " . request('extra_field'))
    ->get();

DB::statement("DROP TABLE IF EXISTS " . request('table_name'));
DB::unprepared("UPDATE users SET admin = 1 WHERE id = " . request('id'));
```

### 1.2 SQL Injection — Eloquent ORM

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 10 | `Model::whereRaw($userInput)` | Same as query builder — any `whereRaw` on an Eloquent model | CWE-89 | **Confirmed** |
| 11 | `Model::orderByRaw($userInput)` | Eloquent model raw sort order | CWE-89 | **Confirmed** |
| 12 | `Model::selectRaw($userInput)` | Eloquent model raw selection | CWE-89 | **Confirmed** |
| 13 | `Model::havingRaw($userInput)` | Eloquent model raw filter | CWE-89 | **Confirmed** |
| 14 | `Model::groupByRaw($userInput)` | Eloquent model raw group | CWE-89 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: Eloquent raw methods
User::whereRaw("email = '" . request('email') . "'")->first();
User::orderByRaw(request('sort'))->get();
```

### 1.3 Blade SSTI / Template Injection

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 15 | `Blade::render($userTemplate, $data)` | Rendering a user-controlled template string → attacker controls the template and can inject `@php` directives for RCE | CWE-94 | **Confirmed** |
| 16 | `{!! $userVar !!}` unescaped output | Blade's unescaped `{!! !!}` syntax bypasses `htmlspecialchars()` → XSS; can also leak Blade expression context | CWE-79 | **Confirmed** |
| 17 | `@include($userPath)` | Dynamic view inclusion from user input → path traversal, LFI, potential SSTI if attacker controls the included file | CWE-98 | **Confirmed** |
| 18 | `@inject('var', $userClass)` | Injects arbitrary class from container → attacker can instantiate any auto-loadable class | CWE-94 | **Likely** |
| 19 | `<x-dynamic-component :component="$userInput" />` | Renders arbitrary Blade component from user input → logic bypass, class instantiation | CWE-94 | **Likely** |

**Examples:**
```php
// VULNERABLE: User-controlled Blade template
Blade::render('Hello {{ $name }}', ['name' => request('name')]);
// Safe if just name is controlled, but dangerous if template string is controlled

// CRITICAL: Template string controlled by attacker
$template = request('template'); // e.g. "@php(system('id'))@endphp"
Blade::render($template, []);
```

### 1.4 Container / Application Call Injection

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 20 | `app()->call($userCallable)` | Calls a user-controlled callable through the container → arbitrary method/function execution | CWE-94 | **Confirmed** |
| 21 | `Container::call($userCallable)` | Same as `app()->call` — container-injected call invocation | CWE-94 | **Confirmed** |
| 22 | `Artisan::call($userCommand)` | Executes an Artisan command from user-controlled input → arbitrary command execution | CWE-78 | **Confirmed** |
| 23 | `Bus::dispatch($userJob)` | Dispatches a job to the queue bus from user-controlled class name → arbitrary job execution | CWE-94 | **Likely** |
| 24 | `$userObject->__invoke(...)` | Calling `__invoke` on a user-controlled class name instantiated from user input | CWE-94 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: Container call injection
app()->call(request('callback')); // Attacker controls what method is called

Artisan::call('migrate', ['--force' => true]); // OK with hardcoded
Artisan::call(request('command')); // VULNERABLE: arbitrary command

// VULNERABLE: Invokable injection
$class = request('action');
$instance = app()->make($class);
return $instance(); // Attacker controls the class
```

### 1.5 Validation and Authorization

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 25 | `Validator::make(..., $rules)` with user-controlled rule | If rule string contains user input like `request('rule_field')` in the rules array, attacker can inject validation rules (e.g., `required|regex:...` for ReDoS, or `required|exists:users,email` for blind SQLi via exists rule) | CWE-89 / CWE-400 | **Confirmed** |
| 26 | `Gate::define($ability, $userCallback)` | Defining a Gate policy with user-controlled callback → arbitrary code execution when the gate is evaluated | CWE-94 | **Confirmed** |
| 27 | `Route::redirect($uri, $userDestination)` | Route macro that redirects based on user input → open redirect | CWE-601 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: User-controlled validation rules
$rules = [
    'email' => request('rule'), // Attacker passes "required|exists:users,email"
];
Validator::make(request()->all(), $rules)->validate();

// VULNERABLE: Gate with user callback
Gate::define('admin', request('callback')); // Attacker passes 'system'
```

---

## 2. Symfony Sinks

### 2.1 Process Component — Command Injection

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 28 | `new Process($userCommand)` | Creating a Process from user-controlled command array/string → command injection | CWE-78 | **Confirmed** |
| 29 | `Process::fromShellCommandline($userInput)` | Shell command line with user input concatenated → shell injection via pipes, redirects, `;`, `&&` | CWE-78 | **Confirmed** |
| 30 | `Process::run($userCommand)` / `->mustRun($userCommand)` | Running a user-controlled command in the Process component | CWE-78 | **Confirmed** |
| 31 | `Process::start($userCommand)` without timeout | Starting a long-running subprocess from user input → resource exhaustion, denial of service | CWE-400 | **Likely** |

**Examples:**
```php
use Symfony\Component\Process\Process;

// VULNERABLE: Shell command line with user input
$process = Process::fromShellCommandline('cat ' . $_GET['file']);
$process->run();

// VULNERABLE: Raw command array with user injection
$process = new Process(['cat', $_GET['file']]);
$process->run();
```

### 2.2 Twig SSTI (Server-Side Template Injection)

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 32 | `$twig->createTemplate($userString)->render()` | Creating a Twig template from user-controlled string → template injection, RCE via `_self.env` | CWE-94 | **Confirmed** |
| 33 | `{{ _self.env.registerUndefinedFilterCallback("system") }}{{ _self.env.getFilter("id") }}` | Classic Twig SSTI payload — registers `system` as the undefined filter handler, calls it with `id` | CWE-94 | **Confirmed** |
| 34 | `{{ ['']|filter('system') }}` | Twig 2.x SSTI using the `filter` filter with arbitrary callable | CWE-94 | **Confirmed** |
| 35 | `{{ _self.env.setCache('file:///tmp') }}{{ _self.env.loadTemplate('...') }}` | Twig SSTI leveraging cache control to write files | CWE-94 | **Theoretical** |
| 36 | `twig_escape_filter` / `raw` filter bypass | `{{ user_input|raw }}` — disables auto-escaping → XSS | CWE-79 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: User-controlled Twig template
$twig = new \Twig\Environment($loader);
$template = $twig->createTemplate($_GET['template']); // SSTI
echo $template->render([]);

// Payload: {{ ['id']|filter('system') }}  (Twig 2.x)
// Payload: {{ _self.env.registerUndefinedFilterCallback("system") }}{{ _self.env.getFilter("whoami") }}
```

### 2.3 ExpressionLanguage — Code Injection

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 37 | `ExpressionLanguage::evaluate($userExpression)` | Evaluating a user-controlled expression → code execution within the sandbox; registered functions invoke arbitrary methods | CWE-94 | **Confirmed** |
| 38 | `ExpressionLanguage::lint($userExpression)` | While just parsing, can trigger resource exhaustion on deeply nested expressions | CWE-400 | **Likely** |

**Examples:**
```php
use Symfony\Component\ExpressionLanguage\ExpressionLanguage;

$el = new ExpressionLanguage();
// VULNERABLE: User-controlled expression
$result = $el->evaluate($_GET['expr'], ['user' => $user]);
```

### 2.4 Serializer — Gadget Chains / Deserialization

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 39 | `Serializer::deserialize($userData, $type, $format)` | Deserializing user data with Symfony's Serializer component → object injection via `__construct` / `__destruct` gadget chains | CWE-502 | **Confirmed** |
| 40 | `Serializer::decode($userData, $format)` | Low-level decode bypasses type restrictions → array/object confusion | CWE-502 | **Likely** |
| 41 | `ObjectNormalizer` / `GetSetMethodNormalizer` with user data | Symfony's normalizers can instantiate arbitrary classes from user input when denormalizing | CWE-502 | **Confirmed** |

**Examples:**
```php
use Symfony\Component\Serializer\Serializer;

// VULNERABLE: Deserialization from user data
$serializer = new Serializer([new ObjectNormalizer()], [new JsonEncoder()]);
$user = $serializer->deserialize($_GET['data'], User::class, 'json');
// If ObjectNormalizer has no allowed_classes restriction, attacker can inject any class
```

### 2.5 Doctrine — DQL Injection

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 42 | `EntityManager::createQuery($userDQL)` | Creates a DQL query from user-controlled string → DQL injection | CWE-89 | **Confirmed** |
| 43 | `QueryBuilder` raw `where()` / `andWhere()` / `orWhere()` with `$userInput` | Using query builder with string concatenation instead of parameter binding | CWE-89 | **Confirmed** |
| 44 | `$qb->expr()->...` with user input in column positions | Where expression builder methods where the field/column argument comes from user data (e.g. `$expr->like($userField, ...)`) | CWE-89 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: DQL with string concatenation
$em->createQuery("SELECT u FROM User u WHERE u.name = '" . $_GET['name'] . "'");

// VULNERABLE: QueryBuilder raw where
$qb->where("u.name = '" . $_GET['name'] . "'");
```

### 2.6 HttpFoundation — File Upload / Trust Issues

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 45 | `FileBag` / `UploadedFile` without MIME validation | Accepting uploaded files without validating MIME type → arbitrary file upload | CWE-434 | **Confirmed** |
| 46 | `Request::getContent()` / `getContentType()` trust | Trusting the `Content-Type` header or raw request body without validation | CWE-345 | **Likely** |
| 47 | `Request::getClientIp()` trust | Trusting `X-Forwarded-For` for IP-based access control without verifying trusted proxies configuration | CWE-807 | **Confirmed** |

---

## 3. WordPress Sinks

### 3.1 WPDB — SQL Injection

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 48 | `$wpdb->query($userSql)` | Executes a raw SQL string with user input concatenated → direct SQL injection | CWE-89 | **Confirmed** |
| 49 | `$wpdb->get_var($userSql)` | Gets a single variable from raw SQL with user input | CWE-89 | **Confirmed** |
| 50 | `$wpdb->get_results($userSql)` | Gets result rows from user-interpolated SQL | CWE-89 | **Confirmed** |
| 51 | `$wpdb->get_row($userSql)` | Gets a single row from user-interpolated SQL | CWE-89 | **Confirmed** |
| 52 | `$wpdb->get_col($userSql)` | Gets a single column from user-interpolated SQL | CWE-89 | **Confirmed** |
| 53 | `$wpdb->prepare()` with `%1$s` / `%2$s` numbered placeholders | Numbered placeholders bypass quoting when `$allow_unsafe_unquoted_parameters` is `true` (default). E.g., `$wpdb->prepare("WHERE (id = %1\$s)", $_GET['id'])` results in unquoted `WHERE (id = id)` | CWE-89 | **Confirmed** |
| 54 | `$wpdb->prepare()` with user-controlled format string | If the query string (first arg to prepare) contains user input, format specifiers can be injected | CWE-89 | **Confirmed** |
| 55 | `$wpdb->escape()` / `_weak_escape()` (deprecated) | Uses `addslashes()` which is bypassable with multibyte charset attacks (GBK, Big5) | CWE-89 | **Confirmed** |
| 56 | `$wpdb->insert()` / `$wpdb->replace()` without format specifiers | If the `$format` array doesn't match the data, type confusion may allow injection | CWE-89 | **Likely** |

**Examples:**
```php
global $wpdb;

// VULNERABLE: Raw SQL in wpdb methods
$wpdb->query("SELECT * FROM {$wpdb->posts} WHERE ID = " . $_GET['id']);
$wpdb->get_var("SELECT COUNT(*) FROM {$wpdb->users} WHERE user_email = '" . $_GET['email'] . "'");

// VULNERABLE: Unquoted numbered placeholders
$wpdb->prepare("WHERE id = %1\$s", $_GET['id']);
// Input: "id"  →  WHERE id = id  (unquoted!)

// VULNERABLE: Deprecated escape
$safe = $wpdb->escape($_GET['input']); // Uses addslashes - charset bypassable
```

### 3.2 WP_Query / WP_User_Query — Meta Injection

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 57 | `WP_Query(['meta_key' => $userInput, 'meta_value' => $userInput])` | User-controlled meta query parameters → SQL injection via meta value; also order/orderby injection | CWE-89 | **Confirmed** |
| 58 | `WP_User_Query(['meta_key' => $userInput])` | User-controlled meta key in user queries | CWE-89 | **Confirmed** |
| 59 | `$query->query($userQueryString)` | `WP_Query::query()` with a full query string from user input → arbitrary post retrieval | CWE-89 | **Confirmed** |
| 60 | `$wpdb->posts` / `$wpdb->usermeta` direct table manipulation | Direct table name references without `prepare()` in custom SQL | CWE-89 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: User-controlled meta query
$query = new WP_Query([
    'meta_key' => $_GET['meta_key'],
    'meta_value' => $_GET['meta_value']
]);
```

### 3.3 WordPress Redirect Sinks

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 61 | `wp_redirect($userUrl)` without `exit;` | Redirects to user-controlled URL. Without `exit` or `wp_die()`, script continues executing → open redirect + auth bypass | CWE-601 | **Confirmed** |
| 62 | `wp_safe_redirect($userUrl)` with bypass | `wp_safe_redirect` validates against allowed hosts but can be bypassed via URL parsing discrepancies (e.g., `https://evilsite.com@legitsite.com`), or via `//evil.com` protocol-relative URLs | CWE-601 | **Confirmed** |
| 63 | `wp_redirect()` / `wp_safe_redirect()` with `X-Forwarded-Host` manipulation | Combined with cache poisoning to make CDN cache the redirect | CWE-601 | **Theoretical** |

**Examples:**
```php
// VULNERABLE: Open redirect
wp_redirect($_GET['url']);
// Input: "http://evil.com/phish"  →  redirects to evil.com

// Missing exit after redirect
wp_redirect(home_url());
// ... more code that checks auth but never gets the exit
```

### 3.4 WordPress Filter/Action Hooks — Callback Injection

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 64 | `add_action($hook, $userCallback)` | Registering a user-controlled callback for a WordPress action → RCE when action fires | CWE-94 | **Confirmed** |
| 65 | `add_filter($hook, $userCallback)` | Registering a user-controlled filter callback → RCE when filter is applied | CWE-94 | **Confirmed** |
| 66 | `do_action($hook, $userData)` | Triggering an action with user-controlled data → attacker data reaches arbitrary listeners | CWE-94 | **Confirmed** |
| 67 | `apply_filters($hook, $userData)` | Applying a filter with user-controlled data → attacker data is transformed by arbitrary registered filters | CWE-94 | **Confirmed** |
| 68 | `remove_action()` / `remove_filter()` with user-controlled hook | Removing security-related hooks based on user input | CWE-754 | **Likely** |

**Examples:**
```php
// VULNERABLE: User-controlled callback
add_action('init', $_GET['callback']); // RCE on init

// VULNERABLE: User data passed to filter
echo apply_filters('the_content', $_GET['data']); // XSS
```

### 3.5 WordPress Email / HTTP / File Sinks

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 69 | `wp_mail($to, $subject, $message, $userHeaders)` | User-controlled headers in `wp_mail` → CRLF injection, spam relay, RCE via `X-` header injection | CWE-93 | **Confirmed** |
| 70 | `wp_remote_get($userUrl)` / `wp_remote_post($userUrl)` | Performing HTTP requests to user-controlled URLs → SSRF | CWE-918 | **Confirmed** |
| 71 | `download_url($userUrl)` / `wp_remote_get()` for file downloads | Downloading a file from a user-controlled URL → SSRF, arbitrary file write | CWE-918, CWE-434 | **Confirmed** |
| 72 | `get_template_part($userSlug)` | Including a template part from user input → LFI, path traversal | CWE-98 | **Confirmed** |
| 73 | `include` / `require` with user input in theme/plugin files | Direct PHP include with user-controlled path in WordPress context → LFI → RCE via log poisoning | CWE-98 | **Confirmed** |
| 74 | `WP_Filesystem::put_contents($userPath, $data)` | Writing to a user-controlled file path via WordPress filesystem API | CWE-22 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: Mail header injection
wp_mail($to, $subject, $message, "Bcc: " . $_GET['bcc'] . "\r\nBcc: spam@evil.com");

// VULNERABLE: SSRF
$response = wp_remote_get($_GET['url']);

// VULNERABLE: LFI via template part
get_template_part('template-parts/' . $_GET['section']);
// Input: "../../../../etc/passwd"  →  path traversal

// VULNERABLE: Direct include
include $_GET['file'] . '.php';
```

### 3.6 WordPress Deserialization / PHP Object Injection

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 75 | `maybe_unserialize($userInput)` | WordPress core function that conditionally unserializes data → if input is a serialized string, it calls `unserialize()` directly | CWE-502 | **Confirmed** |
| 76 | `get_option()` with serialized data | Reading WordPress options that contain serialized PHP objects → trigger gadget chains on retrieval | CWE-502 | **Confirmed** |
| 77 | WordPress REST API `meta_input` with serialized payload | Post meta via REST API accepting serialized data → PHP object injection | CWE-502 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: maybe_unserialize on user input
$data = maybe_unserialize($_POST['data']);
// If $_POST['data'] = 'O:20:"WP_FeedCache":1:{s:5:"items";a:1:{...}}'  →  POP chain

// VULNERABLE: REST API meta injection
// POST /wp-json/wp/v2/posts/1
// Body: {"meta": {"_thumbnail_id": "O:14:"SomeGadget":0:{}"}}
```

---

## 4. Drupal Sinks

### 4.1 SQL Injection — Legacy Database API

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 78 | `db_query($userSql)` (deprecated Drupal 7-8) | Direct SQL execution with string concatenation → SQL injection. Deprecated in Drupal 8+, but still in legacy modules | CWE-89 | **Confirmed** |
| 79 | `db_select($table)` with user conditions in `condition()` / `where()` | Dynamic query builder with user-controlled condition strings → SQL injection | CWE-89 | **Confirmed** |
| 80 | `db_query_range($userSql)` / `db_query_temporary($userSql)` | Deprecated variants of `db_query` with user-interpolated SQL | CWE-89 | **Confirmed** |
| 81 | `db_delete()` / `db_update()` with user conditions | Risky when condition values aren't parameterized properly | CWE-89 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: db_query with string concatenation
$result = db_query("SELECT * FROM {users} WHERE name = '" . $_GET['name'] . "'");

// VULNERABLE: db_select with unsanitized conditions
$query = db_select('users', 'u')
  ->condition('u.name', $_GET['name']); // Safe-ish with scalar
  ->where("u.created > " . $_GET['time']); // VULNERABLE - raw WHERE
```

### 4.2 Drupal Service/Container Injection

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 82 | `\Drupal::service($userServiceId)` | Loading a Drupal service from user-controlled service ID → can retrieve any registered service | CWE-94 | **Confirmed** |
| 83 | `\Drupal::entityTypeManager()->getStorage($userEntityType)` | Loading entity storage for user-controlled type → potential info disclosure, SQL injection in entity queries | CWE-89 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: User-controlled service
$service = \Drupal::service($_GET['service']);
// e.g., "database" → DB access, "entity.query.sql" → query access

// VULNERABLE: User-controlled entity type
$storage = \Drupal::entityTypeManager()->getStorage($_GET['entity']);
```

### 4.3 Drupal URL / Request Handling

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 84 | `Url::fromUserInput($userPath)` | Creates a URL from user-controlled input → open redirect, SSRF, path traversal | CWE-601 | **Confirmed** |
| 85 | `\Drupal::request()->get($userKey)` / `request->query->get()` | Accessing request data without proper validation → trust issues | CWE-345 | **Confirmed** |
| 86 | `\Drupal::httpClient()->get($userUrl)` | Performing HTTP GET to user-controlled URL → SSRF | CWE-918 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: URL from user input
$url = Url::fromUserInput($_GET['path']);
// Attacker can use "base://..." or "../" paths

// VULNERABLE: SSRF via HTTP client
$response = \Drupal::httpClient()->get($_GET['url']);
```

### 4.4 Drupal Form / Render API

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 87 | `\Drupal::formBuilder()->submitForm($userFormId, $data)` | Submitting a user-controlled form class → arbitrary form processing | CWE-94 | **Confirmed** |
| 88 | Drupal Render API with `#type` / `#markup` from user input | Setting `#markup` or `#type` from user data → XSS via render array | CWE-79 | **Confirmed** |
| 89 | `\Drupal\Core\Render\RendererInterface::render()` with user-controlled `#pre_render` callbacks | The `#pre_render` array specifies callbacks that are invoked during rendering. If user controls this, they get arbitrary callback execution | CWE-94 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: User data in render array
$build = [
    '#markup' => $_GET['content'], // XSS
    '#allowed_tags' => ['script'], // Dangerous allowed tag
];

// VULNERABLE: Pre-render callback injection
$build = [
    '#markup' => 'Hello',
    '#pre_render' => [$_GET['callback']], // RCE
];
```

---

## 5. CodeIgniter Sinks

### 5.1 Database / Query Builder

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 90 | `$this->db->query($userSql)` | Executing raw SQL with string interpolation → SQL injection | CWE-89 | **Confirmed** |
| 91 | `$this->db->where($userKey, $value)` | Using user input as the key/field name in where clause → SQL injection via unprotected field names | CWE-89 | **Confirmed** |
| 92 | `$this->db->or_where($userKey, $value)` | Same as `where()` with user-controlled key | CWE-89 | **Confirmed** |
| 93 | `$this->db->having($userKey, $value)` | User-controlled key in HAVING clause | CWE-89 | **Confirmed** |
| 94 | `$this->db->like($field, $userMatch)` / `or_like()` | User-controlled match value in LIKE clause (safe for value, but field name derived from user data is injection) | CWE-89 | **Confirmed** |
| 95 | `$this->db->order_by($userField, $direction)` | User-controlled column name in ORDER BY — cannot be parameterized, must be whitelisted | CWE-89 | **Confirmed** |
| 96 | `$this->db->select($userFields)` | User-controlled select expression → SQL injection | CWE-89 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: Raw query
$this->db->query("SELECT * FROM users WHERE id = " . $this->input->get('id'));

// VULNERABLE: User-controlled field key in where
$this->db->where($this->input->post('field'), $value);
// Input: field="1=1 UNION SELECT * FROM users"

// VULNERABLE: Order by injection
$this->db->order_by($this->input->get('sort'), 'ASC');
// Input: sort="id, (SELECT password FROM users LIMIT 1)"
```

### 5.2 Input / Security Class

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 97 | `$this->input->get($key)` without XSS filtering | Trusting GET input even when XSS filtering is disabled (default if second arg is not passed) | CWE-79 | **Confirmed** |
| 98 | `$this->input->post($key)` without validation | Using raw POST input without checking against validation rules | CWE-20 | **Confirmed** |
| 99 | `$this->security->xss_clean($userInput)` reliance | Relying on CodeIgniter's XSS filter for sanitization (bypassable, especially via double encoding, DOM clobbering) | CWE-79 | **Confirmed** |

### 5.3 Template / View Sinks

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 100 | `eval($userTemplateCode)` in CI templates | Custom template engines in CodeIgniter that eval user input → RCE | CWE-95 | **Confirmed** |
| 101 | `$this->load->view($userPath, $data)` | Loading a view from user-controlled path → LFI | CWE-98 | **Confirmed** |
| 102 | `$this->parser->parse($userTemplate)` | CodeIgniter's built-in template parser with user-controlled template string → template injection | CWE-94 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: Dynamic view load
$this->load->view($this->input->get('page'), $data);
// Input: page="../../etc/passwd"  →  LFI (with .php appended?)

// VULNERABLE: Parser template string
$this->parser->parse($this->input->post('template'), $data);
```

---

## 6. Yii Framework Sinks

### 6.1 Database / DAO

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 103 | `Yii::$app->db->createCommand($userSql)` | Creating a raw SQL command from user-interpolated string → SQL injection | CWE-89 | **Confirmed** |
| 104 | `Yii::$app->db->createCommand()->query($userSql)` | Raw query execution with user input | CWE-89 | **Confirmed** |
| 105 | `Connection::createCommand($userSql)` | Same as above — raw SQL via connection | CWE-89 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: Raw SQL in createCommand
Yii::$app->db->createCommand("SELECT * FROM user WHERE id = " . $_GET['id'])->queryAll();
```

### 6.2 Query Builder / ActiveRecord

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 106 | `Query::where([$userColumn => $value])` | Using user-controlled column name in query condition → SQL injection in column position | CWE-89 | **Confirmed** |
| 107 | `Query::andWhere($userCondition)` / `orWhere($userCondition)` | Raw condition strings from user input in query builder | CWE-89 | **Confirmed** |
| 108 | `ActiveRecord::findBySql($userSql)` | Finding by raw SQL from user input | CWE-89 | **Confirmed** |
| 109 | `ActiveRecord::updateAllCounters($counters, $userCondition)` | User-controlled condition in batch update | CWE-89 | **Confirmed** |
| 110 | `ActiveRecord::deleteAll($userCondition)` | User-controlled condition in batch delete → mass deletion | CWE-89 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: User-controlled column name
$query = (new Query())
    ->from('user')
    ->where([$_GET['column'] => $_GET['value']]) // column is injected
    ->all();

// VULNERABLE: Raw condition string
$query->andWhere("status = '" . $_GET['status'] . "'");

// VULNERABLE: Find by SQL
User::findBySql("SELECT * FROM user WHERE id = " . $_GET['id']);
```

### 6.3 Input / Request Handling

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 111 | `Yii::$app->request->get($key)` without validation | Trusting raw GET/POST input without type validation or filtering | CWE-20 | **Confirmed** |
| 112 | `Yii::$app->request->post($key)` without validation | Same trust issue with POST data | CWE-20 | **Confirmed** |
| 113 | `ArrayHelper::getValue($array, $userPath)` | Using dot-notation path from user input to traverse arrays → can read arbitrary nested values | CWE-200 | **Confirmed** |
| 114 | `ArrayHelper::remove($array, $userPath)` | Same as getValue but removes — can manipulate arbitrary nested structure | CWE-20 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: ArrayHelper path injection
$value = ArrayHelper::getValue($userData, $_GET['path']);
// Input: path="user.password"  →  reads password from nested array

// VULNERABLE: Request data without validation
$id = Yii::$app->request->get('id');
User::findOne($id); // OK if $id is PK, but depends on type
```

### 6.4 Yii Configuration / Object Creation

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 115 | `Yii::createObject($config)` with user-controlled config | Creating objects from user-controlled configuration → arbitrary class instantiation, property injection | CWE-94 | **Confirmed** |
| 116 | `Yii::configure($object, $userProperties)` | Setting object properties from user input → property injection, RCE via sensitive property overwrites | CWE-94 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: User-controlled object creation
$obj = Yii::createObject([
    'class' => $_GET['class'], // Attacker picks the class
    'property1' => $_GET['val'],
]);

// VULNERABLE: Property injection
$user = new User();
Yii::configure($user, $_POST['User']); // Attacker sets any accessible property
```

---

## 7. CakePHP Sinks

### 7.1 Database / Connection Layer

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 117 | `$connection->execute($userSql)` | `execute()` supports parameter binding but if user input is interpolated into the SQL string → SQL injection | CWE-89 | **Confirmed** |
| 118 | `$connection->query($userSql)` | `query()` takes raw SQL with NO parameter support → SQL injection if any user input is concatenated | CWE-89 | **Confirmed** |
| 119 | `$connection->prepare($userSql)->execute()` | If the SQL string passed to prepare contains user input → SQL injection | CWE-89 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: Raw query with string concat
$connection->execute("SELECT * FROM articles WHERE id = " . $this->request->getQuery('id'));
$connection->query("DELETE FROM articles WHERE id = " . $this->request->getData('id'));
```

### 7.2 Query Builder / ORM

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 120 | `Table::find()->where([$userKey => $value])` | User-controlled key in array conditions — the key is inserted into SQL as-is → injection | CWE-89 | **Confirmed** |
| 121 | `Table::find()->where([$userData])` | Single-value entries in where array are interpreted as raw SQL | CWE-89 | **Confirmed** |
| 122 | `$query->where(["RAW SQL $userData"])` | Raw SQL snippets in where clauses with user data | CWE-89 | **Confirmed** |
| 123 | `$query->epilog($userData)` | Appending raw SQL after the query — documented as "never put raw user data into epilog()" | CWE-89 | **Confirmed** |
| 124 | `$query->newExpr()->add($userData)` | Creating expression objects from user data — documented as "vulnerable to SQL injection" | CWE-89 | **Confirmed** |
| 125 | `$exp->in($userColumn, $values)` | User-controlled column name in expression's `in()` method | CWE-89 | **Confirmed** |
| 126 | `$query->func()->{$userFunction}($args)` | User-controlled function name in query functions | CWE-89 | **Confirmed** |
| 127 | `$case->when($userData)` | Raw user data in case expression's when clause | CWE-89 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: Table::find with user conditions
$articles = TableRegistry::get('Articles')->find()
    ->where([
        $this->request->getQuery('field') => $value, // key is injected
        // Or:
        $this->request->getQuery('rawCondition'), // raw SQL single entry
    ])
    ->epilog($this->request->getQuery('epilog')) // raw SQL tail
    ->all();

// VULNERABLE: Function injection
$query->func()->{$this->request->getData('func')}($arg);
```

### 7.3 Form / Request Handling

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 128 | `$this->request->getData($key)` without validation | Trusting form data without using the Validator component | CWE-20 | **Confirmed** |
| 129 | `$this->request->getQuery($key)` without type casting | Trusting query string parameters as-is | CWE-20 | **Confirmed** |
| 130 | `Router::url($userUrl)` with full URL | Generating URLs from user-controlled input → open redirect | CWE-601 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: Request data trust
$id = $this->request->getData('id'); // string "1 OR 1=1"
$connection->execute("SELECT * FROM articles WHERE id = $id"); // SQLi
```

---

## 8. Generic PHP Template Engines

### 8.1 Smarty Template Injection

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 131 | `{eval var=$userString}` / `{eval $userVar}` | Smarty's `{eval}` tag evaluates a variable as a template → RCE if any user data is in the eval'd string | CWE-94 | **Confirmed** |
| 132 | `{php}` ... `{/php}` tags | Smarty `{php}` tag executes arbitrary PHP code — if attacker can inject this into a template → RCE | CWE-94 | **Confirmed** |
| 133 | Smarty resource injection: `template: $smarty->display("resource:$userInput")` | Loading template from user-controlled resource (`eval:`, `string:`, `file:`) → RCE via `string:` resource | CWE-94 | **Confirmed** |
| 134 | `$smarty->fetch($userTemplate)` / `$smarty->display($userTemplate)` | Rendering a template from user-controlled path/string source | CWE-94 | **Confirmed** |
| 135 | `$smarty->registerPlugin()` / `registerObject()` with user callback | Registering a user-controlled callback as a Smarty plugin → RCE when template invokes it | CWE-94 | **Confirmed** |
| 136 | `{literal}` bypass via `{/literal}` injection | If user content is wrapped in `{literal}` but the attacker can close it, they can inject arbitrary Smarty tags | CWE-94 | **Theoretical** |

**Examples:**
```php
// VULNERABLE: Smarty eval
$smarty->assign('userTemplate', $_GET['tpl']);
$smarty->display('template.tpl');
// In template: {eval var=$userTemplate}
// Payload: {php}system('id');{/php}

// VULNERABLE: Resource injection
$smarty->display('string:' . $_GET['template']);
// Payload: template={php}phpinfo();{/php}

// VULNERABLE: User-controlled template path
$smarty->display($_GET['page'] . '.tpl');
```

### 8.2 Twig — Additional SSTI Vectors

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 137 | `$loader->getSource($userTemplate)` → `$twig->loadTemplate()` | Loading a template from user-controlled name → path traversal, arbitrary file inclusion | CWE-98 | **Confirmed** |
| 138 | Twig `registerUndefinedFilterCallback` chain | `{{ _self.env.registerUndefinedFilterCallback("exec") }}{{ _self.env.getFilter("id") }}` — classic Twig SSTI RCE | CWE-94 | **Confirmed** |
| 139 | Twig `filter('system')` filter injection (Twig 2.x) | `{{ ['id']|filter('system') }}` — uses `array_filter` with user-provided callback | CWE-94 | **Confirmed** |
| 140 | Twig `map` / `reduce` filter injection | `{{ [0]|map('system') }}` or `{{ [0]|reduce('system', 'id') }}` — callback injection via map/reduce filters | CWE-94 | **Confirmed** |
| 141 | Twig `sort` filter injection | `{{ [0]|sort('system') }}` — callback injection via sort filter callback argument | CWE-94 | **Confirmed** |
| 142 | Twig using `_self.env.setCache()` to set cache directory | `{{ _self.env.setCache('/tmp') }}` — can be used to write compiled templates to attacker-chosen location | CWE-22 | **Theoretical** |
| 143 | Twig sandbox bypass via `__toString()` gadgets | In sandbox mode, calling `{{ object }}` triggers `__toString()` on the object, which may lead to gadget chain exploitation | CWE-502 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: Twig template from user-controlled source
$loader->addPath('/var/templates');
$template = $twig->load($_GET['template']); // Path traversal to ../../etc/passwd

// VULNERABLE: Twig SSTI payloads
// {{ ['id']|filter('system') }}
// {{ ['cat /etc/passwd']|map('file_get_contents') }}
// {{ _self.env.registerUndefinedFilterCallback("exec") }}{{ _self.env.getFilter("cat /etc/passwd") }}
```

### 8.3 Mustache / Handlebars (PHP)

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 144 | Mustache lambda tags — `{{#lambda}}...{{/lambda}}` | Mustache lambdas can execute arbitrary PHP if defined with user-controlled callback | CWE-94 | **Confirmed** |
| 145 | `$mustache->loadTemplate($userTemplate)` | Loading Mustache template from user-controlled source → template injection if template is not escaped | CWE-94 | **Confirmed** |
| 146 | `$mustache->render($userTemplate, $data)` | Rendering user-controlled template string | CWE-94 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: Mustache lambda with user callback
$m = new Mustache_Engine([
    'helpers' => [
        'lambda' => $_GET['callback'], // Function name from user
    ],
]);
echo $m->render('{{#lambda}}{{/lambda}}', []);

// VULNERABLE: User-controlled template
echo $m->render($_GET['template'], $data);
```

### 8.4 Volt (Phalcon Template Engine)

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 147 | Volt `{% if $userExpression %}` — Expression injection | Volt compiles to PHP and evaluates expressions — user-controlled expressions can execute arbitrary code | CWE-94 | **Confirmed** |
| 148 | Volt `{{ $userVar | eval }}` | The `eval` filter in Volt evaluates PHP code from user-controlled variable | CWE-94 | **Confirmed** |
| 149 | Volt `{% include $userPath %}` | Including templates from user-controlled path | CWE-98 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: Volt with user expression
// In template: {% if user_expression %}
// With: user_expression = "system('id')"

// VULNERABLE: Volt include
// {% include user_page %}
// With: user_page = "../../../etc/passwd"
```

### 8.5 Plates (PHP Template Engine)

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 150 | `$templates->render($userTemplate, $data)` | Rendering a user-controlled template name → LFI/path traversal | CWE-98 | **Confirmed** |
| 151 | Plates `$this->fetch($userPath)` | Fetching and rendering a nested template from user-controlled path | CWE-98 | **Confirmed** |
| 152 | Plates `escape()` bypass with raw `<?=` tags | If user content contains raw PHP tags and Plates doesn't escape them (since it's PHP-based, not sandboxed), XSS/RCE | CWE-79 | **Theoretical** |

**Examples:**
```php
// VULNERABLE: Plates template from user input
$templates->render($_GET['page'], $data);
// Input: "../../tmp/evil" → path traversal
```

### 8.6 Blade (Standalone) — Additional

| # | Pattern | Description | CWE | Confidence |
|---|---------|-------------|-----|------------|
| 153 | `@php` directive injection in user content | If user content is rendered through Blade without escaping, `@php system('id') @endphp` executes | CWE-94 | **Confirmed** |
| 154 | `@include($userPath)` (standalone Blade) | Path traversal via dynamic includes — same as Laravel `@include` | CWE-98 | **Confirmed** |
| 155 | `@component` / `@slot` injection | Dynamic component names from user input lead to arbitrary class loading | CWE-94 | **Likely** |
| 156 | Custom `Blade::directive()` with unsafe expression concatenation | If directive callback concatenates expression into PHP output without proper escaping, expression injection → RCE | CWE-94 | **Confirmed** |

**Examples:**
```php
// VULNERABLE: Injection via @php in user content
// If user content is rendered: Hello @php system('id') @endphp User

// VULNERABLE: Custom directive
Blade::directive('unsafe', function ($expr) {
    return "<?php echo $expr; ?>"; // Expression injection
});
// Usage: @unsafe($_GET['cmd']) → breaks out
```

---

## Summary Statistics

| Category | Confirmed | Likely | Theoretical | Total |
|----------|-----------|--------|-------------|-------|
| Laravel | 20 | 3 | 0 | 23 |
| Symfony | 11 | 3 | 1 | 15 |
| WordPress | 22 | 2 | 2 | 26 |
| Drupal | 8 | 0 | 0 | 8 |
| CodeIgniter | 10 | 0 | 0 | 10 |
| Yii | 10 | 0 | 0 | 10 |
| CakePHP | 11 | 0 | 0 | 11 |
| Generic Template Engines | 17 | 1 | 3 | 21 |
| **Total Unique Sinks** | **109** | **9** | **6** | **124** |

> Note: Some sinks may overlap between frameworks (e.g., `whereRaw` in Laravel appears in both query builder and Eloquent contexts).

---

## References

- Laravel Docs: [Raw Expressions](https://laravel.com/docs/11.x/queries#raw-expressions), [Blade Templates](https://laravel.com/docs/11.x/blade)
- Symfony Docs: [Process Component](https://symfony.com/doc/current/components/process.html), [ExpressionLanguage](https://symfony.com/doc/current/components/expression_language.html), [Serializer](https://symfony.com/doc/current/components/serializer.html)
- WordPress Docs: [wpdb Class](https://developer.wordpress.org/reference/classes/wpdb/), [Plugin Security](https://developer.wordpress.org/plugins/security/)
- Drupal Docs: [Database API](https://www.drupal.org/docs/develop/drupal-apis/database-api), [Security](https://www.drupal.org/docs/develop/security)
- CodeIgniter Docs: [Database Queries](https://codeigniter.com/userguide3/database/queries.html), [Security](https://codeigniter.com/userguide3/libraries/security.html)
- Yii Framework: [Security Best Practices](https://www.yiiframework.com/doc/guide/2.0/en/security-best-practices)
- CakePHP Docs: [Query Builder](https://book.cakephp.org/4/en/orm/query-builder.html), [Database Basics](https://book.cakephp.org/4/en/orm/database-basics.html)
- Smarty: [Security](https://smarty-php.com/docs/security)
- Twig: [Templates](https://twig.symfony.com/doc/3.x/templates.html)
- [HackTricks - PHP Useful Functions](https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/php-tricks-esp/php-useful-functions-disable-functions-bypass)
- [OWASP Deserialization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Deserialization_Cheat_Sheet.html)
