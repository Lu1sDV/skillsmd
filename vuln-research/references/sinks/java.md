# Java Security Sinks — Comprehensive Reference

> **Sidecar files** (lossless split): `java.citations.jsonl` (one structured citation per line, keyed by `sink_id`) and `java.snippets/<sink_id>.<ext>` (PoC code blocks). In-doc tokens `[citation:ID]` and `[snippet:ID]` link to them.

> **Generated**: 2026-05-09 via 11-agent parallel research swarm. JSON defaults: `verified:true`, `confidence:"confirmed"` unless noted. URLs for CVE/JEP/JDK/CERT/GHSA IDs are deterministic and omitted from migrated extras.

---

## Quick Reference (Well-Known Sinks)

### RCE
`Runtime.getRuntime().exec()`, `ProcessBuilder.start()`, `ScriptEngine.eval()` (Nashorn, GraalJS), EL injection (`javax.el.*`), OGNL (`ognl.Ognl.getValue()`), SpEL (`SpelExpressionParser.parseExpression()`), MVEL (`MVEL.eval()`), JEXL (`JexlEngine.createExpression()`)

### Deserialization
`ObjectInputStream.readObject/readUnshared()`, `XMLDecoder.readObject()`, `XStream.fromXML()`, `SnakeYAML Yaml.load()`, `Jackson ObjectMapper.readValue()` with `enableDefaultTyping()` or `@JsonTypeInfo`, `Kryo.readObject()`, `Hessian2Input.readObject()`, `JMX MBeanServer`, `RMI registry` — use ysoserial/ysoserial-modified for gadget chains

**Format-specific deserialization sinks:**
- **JSON:** `Fastjson JSON.parseObject()` (1.2.24 JNDI, 1.2.47 cache poison), `Flexjson JSONDeserializer.deserialize()`, `Genson genson.deserialize()`, `json-io JsonReader.jsonToJava()`, `Jodd jsonParser.parse()`
- **YAML:** `SnakeYAML Yaml.load()` (ScriptEngineManager gadget), `jYAML Yaml.loadType()`, `YamlBeans YamlReader`
- **XML:** `XMLDecoder.readObject()`, `Castor Unmarshaller.unmarshal()`
- **Binary:** `Hessian2Input.readObject()` (MobileIron CVE-2020-15505, Dubbo), `Kryo readClassAndObject()`, AMF (BlazeDS/Flamingo/GraniteDS/Red5)
- **No-fix sinks:** Apache XML-RPC all versions (no patch available)

### JNDI Injection
`InitialContext.lookup(userInput)`, `JndiTemplate.lookup()`, `JdbcRowSet.setDataSourceName()` — protocols: `rmi://`, `ldap://`, `dns://`, `iiop://`

### SSRF
`URL.openConnection()`, `URL.openStream()`, `HttpURLConnection`, `HttpClient.send()`, `RestTemplate.getForObject()`, `WebClient.get()`, `OkHttpClient`, `Apache HttpClient`

### SQLi
`Statement.executeQuery(string_concat)`, `PreparedStatement` with string concat (misuse), `createQuery()` (JPA/Hibernate with concat), `createNativeQuery()`, `JdbcTemplate.queryForObject()` with string concat

### Additional Sinks
- **XXE:** `DocumentBuilderFactory.newInstance()` without `setFeature(XMLConstants.FEATURE_SECURE_PROCESSING)`, `SAXParserFactory`, `XMLInputFactory`, `TransformerFactory`, `SchemaFactory`, `Unmarshaller`
- **SSTI:** Spring View name injection, Thymeleaf pre-processing `__${...}__`, Freemarker `new()` built-in
- **Path Traversal:** `new File(base, userInput)`, `Paths.get()`, `Files.readAllBytes()` with unsanitized path, `ClassLoader.getResourceAsStream()`
- **LDAP:** `DirContext.search()` with string-concatenated filter, `SpringLdapTemplate.search()`
- **Reflection sinks:** `Class.forName(userInput).newInstance()` / `Method.invoke(null, userInput)`
- **GWT-RPC deserialization:** `//GWT-RPC//` serialized request bodies parsed by `AbstractRemoteServiceServlet`
- **EL engine sinks:** `Ognl.getValue()`, `MVEL.eval()`, `JexlEngine.createExpression().evaluate()`

---

# Deep-Dive: Non-Obvious Java Sinks

## 1. Type System / Class Confusion

### 1.1 `sun.misc.Unsafe` Type Confusion via `putObject` + Shadow Type Mirroring
**Risk:** `Unsafe.putObject()` performs no type checking when writing an object into a field. Combined with a "mirror" class having identical memory layout but different field visibility, this reads/writes private fields of arbitrary JDK classes.

`[snippet:CLASS-J001]`

`[citation:CLASS-J001]`

### 1.2 HotSpot JIT Bytecode Verifier Cache Bypass (CVE-2012-1723)
**Risk:** HotSpot JIT caches field-access verification results. If a method contains two field-access bytecodes (GETSTATIC + PUTFIELD) referencing the same field, only the first is verified. By crafting bytecode confusing STATIC↔FIELD access, an attacker writes a `ClassLoader` reference into an instance field slot — achieving type confusion.

`[snippet:CLASS-J002]`

`[citation:CLASS-J002]`

### 1.3 MethodHandles.tryFinally Throwable Type Confusion (CVE-2018-2826)
**Risk:** `MethodHandles.tryFinally()` performs insufficient type checking on Throwable passed from target to cleanup. The target throws a `Lemon`-typed exception carrying a `Lookup` object; cleanup expects `Lime`. The type mismatch is not validated, enabling the attacker to cast the confused lookup into `LookupMirror` and set `allowedModes = -1`.

`[snippet:CLASS-J003]`

`[citation:CLASS-J003]`

### 1.4 Mutable MethodType Deserialization (CVE-2020-2805)
**Risk:** `MethodType` is supposed to be immutable. During deserialization, a temporary MethodType object transitions between types. By retaining a reference to this mutating temporary via cyclic `ObjectInputStream` references, an attacker coerces a `MethodHandle` through incompatible type transitions.

`[snippet:CLASS-J004]`

`[citation:CLASS-J004]`

### 1.5 AtomicReferenceArray Serialization Type Confusion (CVE-2012-0507)
**Risk:** `AtomicReferenceArray` stores its internal array as `Object[]` but originally had no deserialization type check. An attacker crafts a serialized object graph embedding a typed array inside `AtomicReferenceArray`. Since `AtomicReferenceArray.set()` uses Unsafe internally (no type check), arbitrary objects can be written into the typed array.

`[snippet:CLASS-J005]`

`[citation:CLASS-J005]`

### 1.6 Covariant Arrays + Generics Erasure → Heap Pollution
**Risk:** Java arrays are covariant but generics are invariant. Combined with type erasure (non-reifiable types), generic array creation (`new List<String>[10]`) is forbidden because the runtime type check (`ArrayStoreException`) cannot fire — erased types provide no runtime check. `@SafeVarargs` abuse on varargs methods enables silent heap pollution.

`[snippet:CLASS-J006]`

`[citation:CLASS-J006]`

### 1.7 Maven-Hijack: Class Shadowing via DFS Packaging Order
**Risk:** Maven packages dependencies into uber-JARs using depth-first search. JVM classloader loads the first class matching an FQN. An attacker injects a class (e.g., `org.postgresql.Driver`) into an earlier dependency, silently replacing the legitimate class — no version manipulation needed.

`[snippet:CLASS-J007]`

`[citation:CLASS-J007]`

### 1.8 Generic Type Annotation Resolution Failure (CVE-2025-41248/249)
**Risk:** Spring Security fails to resolve `@PreAuthorize` annotations on methods within type hierarchies with unbounded generics. The annotation detection mechanism misses the security annotation on the generic superclass/interface, resulting in unauthenticated access.

`[snippet:CLASS-J008]`

`[citation:CLASS-J008]`

---

## 2. Concurrency / Race Conditions

### 2.1 Finalizer Attack — Bypassing Constructor Security Checks
**Risk:** A subclass overriding `finalize()` can resurrect a partially constructed object even after the constructor throws a `SecurityException`. The `finalize()` method runs with a fully-mutable instance whose fields may be attacker-controlled.

`[snippet:RACE-J001]`

`[citation:RACE-J001]`

### 2.2 Thread.stop() Monitor Corruption
**Risk:** `ThreadDeath` unwindses stack asynchronously, releasing monitors mid-critical-section. Code that relies on `synchronized` blocks for atomic operations has no defense — a `ThreadDeath` can fire between any two bytecodes, leaving shared state partially updated.

`[snippet:RACE-J002]`

`[citation:RACE-J002]`

### 2.3 Double-Checked Locking Bypass (JMM Reordering)
**Risk:** Without `volatile`, JIT reordering can allow a second thread to see a non-null reference before the constructor completes — exposing an uninitialized object. Fixed in JDK 5+ via JSR-133, but the fix only applies when the field IS volatile.

`[snippet:RACE-J003]`

`[citation:RACE-J003]`

### 2.4 Virtual Threads Silent Deadlock (JDK-8334304)
**Risk:** Pre-Java-24, virtual threads pinned inside `synchronized` blocks exhaust all carrier threads. `ThreadMXBean.findDeadlockedThreads()` returns null — the deadlock is invisible to all standard diagnostic tools.

`[snippet:RACE-J004]`

`[citation:RACE-J004]`

### 2.5 ByteBuffer slice() Race (CVE-2020-2803)
**Risk:** Race between `remaining()` and `position()` allows OOB access on `ByteBuffer`. When combined with `VarHandle`, this bypasses array bounds checking and enables type confusion.

`[snippet:RACE-J005]`

`[citation:RACE-J005]`

### 2.6 PhantomReference Cleaner UAF
**Risk:** After GC enqueues a phantom reference, the object is resurrected via strong references in the `Cleaner`. This creates a use-after-free scenario where native memory backing the object is freed while the Java object is still usable.

`[citation:RACE-J006]`

---

## 3. Standard Library Hidden Sinks

### 3.1 `java.beans.Beans.instantiate()` — Hidden Deserialization Gateway
**Risk:** Accepts a user-controlled bean name that first tries to deserialize a `.ser` resource from the classpath, then falls back to class instantiation. If an attacker controls `beanName`, they can trigger deserialization from any classpath location.

`[snippet:STDLIB-J001]`

`[citation:STDLIB-J001]`

### 3.2 `java.beans.Expression`/`Statement` — Arbitrary Dynamic Method Invocation
**Risk:** `Expression.execute()` and `Statement.execute()` perform dynamic method lookup based on string method names. If an attacker controls target/method/args, they can invoke arbitrary methods including statics.

`[snippet:STDLIB-J002]`

`[citation:STDLIB-J002]`

### 3.3 `java.lang.System.setProperty()` — Runtime Security Gate Bypass
**Risk:** Can re-enable security-disabled features at runtime. Attackers can re-enable unsafe Commons Collections deserialization, JNDI remote class loading, or Nashorn sandboxing.

`[snippet:STDLIB-J003]`

`[citation:STDLIB-J003]`

### 3.4 `javax.script.ScriptEngine.eval()` — Nashorn Sandbox Bypass (CVE-2025-30761)
**Risk:** Nashorn's `--no-java` sandbox and `ClassFilter` can be bypassed via the `this.engine` property or the `factory.scriptEngine` escape.

`[snippet:STDLIB-J004]`

`[citation:STDLIB-J004]`

### 3.5 `java.util.ServiceLoader` — SPI-Based Arbitrary Class Loading
**Risk:** `ServiceLoader` loads and instantiates classes listed in `META-INF/services/<interface>` files from classpath. If the classpath includes remote URLs or attacker-controlled JARs, arbitrary classes get instantiated. Marshalsec's `ServiceLoader` payload uses this for remote codebase loading.

`[snippet:STDLIB-J005]`

`[citation:STDLIB-J005]`

### 3.6 `javax.tools.JavaCompiler.run()` — On-the-Fly Compilation of Untrusted Code (CVE-2025-30691)
**Risk:** If an application compiles user-provided Java source code at runtime using `JavaCompiler`, attackers can inject malicious code. Annotation processing during compilation runs arbitrary code from the classpath.

`[snippet:STDLIB-J006]`

`[citation:STDLIB-J006]`

### 3.7 `java.net.URL.equals()` DNS Resolution Whitelist Bypass
**Risk:** `URL.equals()` and `hashCode()` perform DNS lookups — two URLs resolving to the same IP are considered equal. An attacker controlling DNS for `evil.com` can make it resolve to the same IP as `trusted.internal`, bypassing whitelist checks.

`[snippet:STDLIB-J007]`

`[citation:STDLIB-J007]`

### 3.8 `java.net.URL` Custom Protocol Handler Injection
**Risk:** `URL.setURLStreamHandlerFactory()` can intercept any protocol including `file://`. The `java.protocol.handler.pkgs` system property enables loading protocol handlers from attacker-specified packages.

`[snippet:STDLIB-J008]`

`[citation:STDLIB-J008]`

### 3.9 `java.util.regex.Pattern` — ReDoS
**Risk:** Nested quantifiers cause exponential backtracking. JDK 9+ memoization mitigates most cases but polynomial O(n²) cases persist and backreferences disable memoization.

`[snippet:STDLIB-J009]`

`[citation:STDLIB-J009]`

### 3.10 JSR 269 Annotation Processor Auto-Execution
**Risk:** javac automatically discovers and executes ANY annotation processor found on the classpath via ServiceLoader (`META-INF/services/javax.annotation.processing.Processor`). A malicious transitive dependency with an annotation processor executes arbitrary code at compile time — silently, with no log output until Java 21+. Supply chain attack vector.

`[snippet:STDLIB-J010]`

`[citation:STDLIB-J010]`

---

## 4. Deserialization Beyond ObjectInputStream

### 4.1 Externalizable → RMI UnicastRef → Secondary readObject Bridge (AMF)
**Risk:** Any AMF deserialization endpoint that interprets `flash.utils.IExternalizable` as `java.io.Externalizable` can chain into full Java deserialization via `UnicastRef`, which creates an outgoing JRMP connection during `readExternal`. The attacker's `JRMPListener` responds with an unfiltered gadget chain — bypassing all inbound stream filters.

`[snippet:DESER-J001]`

`[citation:DESER-J001]`

### 4.2 Hessian2 ProxyLazyValue JDK-Only Gadget Chain (CVE-2024-46983)
**Risk:** SOFA Hessian uses a class-name prefix blacklist that can be bypassed with a JDK-only chain (`TreeMap` → `Rdn$RdnEntry.compareTo` → `UIDefaults.equals` → `ProxyLazyValue.createValue`). Achieves RCE with zero third-party dependencies.

`[snippet:DESER-J002]`

`[citation:DESER-J002]`

### 4.3 SnakeYAML ScriptEngineManager + URLClassLoader SPI (CVE-2022-1471)
**Risk:** `!!` tag syntax instantiates arbitrary Java classes via constructors. `ScriptEngineManager` constructor accepts a `ClassLoader` — combined with `URLClassLoader`, loads remote JARs via SPI, discovering `ScriptEngineFactory` implementations.

`[snippet:DESER-J003]`

`[citation:DESER-J003]`

### 4.4 XStream Blacklist Bypass via SwingLazyValue → JNDI (CVE-2020-26217 variant)
**Risk:** XStream 1.4.15's default blacklist was bypassed using `TreeSet` → `RdnEntry.compareTo` → `XString.equals` → `MultiUIDefaults.toString` → `UIDefaults.get` → `SwingLazyValue.createValue` → `InitialContext.doLookup()`. JDK-only classes — none on the blacklist.

`[snippet:DESER-J004]`

`[citation:DESER-J004]`

### 4.5 Jackson defaultTyping → C3P0 Secondary Deserialization Bridge
**Risk:** Jackson's `enableDefaultTyping` combined with `com.mchange.v2.c3p0.WrapperConnectionPoolDataSource` bridges JSON deserialization into full Java native deserialization. The constructor calls `C3P0ImplUtils.parseUserOverridesAsString()` → `SerializableUtils.fromByteArray()` → `ObjectInputStream.readObject()`.

`[snippet:DESER-J005]`

`[citation:DESER-J005]`

### 4.6 Kryo Constructor + finalize() Exploitation (No Serializable Required)
**Risk:** Kryo deserializes any Java type regardless of `java.io.Serializable`. Constructors (even private) are invoked via reflection, and `finalize()` is triggered on GC doubles the gadget surface.

`[snippet:DESER-J006]`

`[citation:DESER-J006]`

### 4.7 JMX RequiredModelMBean Descriptor Injection
**Risk:** JMX's `RequiredModelMBean` accepts a `ModelMBeanOperationInfo` with a `Descriptor` containing a `class` field. When invoked, it reads the `class` descriptor field and overrides the target class — allowing invocation of ANY public static method on ANY class, regardless of the MBean's actual resource object.

`[snippet:DESER-J007]`

`[citation:DESER-J007]`

### 4.8 RMI JEP 290 Filter Bypass via UnicastRemoteObject/JRMP (An Trinh)
**Risk:** JEP 290 whitelists `java.rmi.Remote` and `RemoteObject` subclasses. `RemoteObjectInvocationHandler` with an attacker-controlled `UnicastRef` passes the whitelist and creates an outgoing JRMP connection during deserialization. The attacker's `JRMPListener` responds with an unfiltered gadget chain.

`[snippet:DESER-J008]`

`[citation:DESER-J008]`

### 4.9 RMI DGC Deserialization Attack via Raw JRMP dirty() Call
**Risk:** Every RMI endpoint has a Distributed Garbage Collector at ObjID=2 with method `dirty(ObjID[], long, Lease)`. Pre-JEP 290, sending a malicious serialized object as the `Lease` argument triggered deserialization on ANY RMI listener — no registry interaction needed.

`[snippet:DESER-J009]`

`[citation:DESER-J009]`

### 4.10 Forged SerializedLambda → Private Method Invocation ($deserializeLambda$)
**Risk:** A forged `SerializedLambda` carries the complete method reference identity. During deserialization, the compiler-generated `$deserializeLambda$` may be abused to invoke arbitrary private static methods. Exploited in ysoserial `Scala1` gadget chain.

`[snippet:DESER-J010]`

`[citation:DESER-J010]`

### 4.11 java.beans.Statement ACC Poisoning (CVE-2012-4681)
**Risk:** `java.beans.Statement` lost its internal package-access checks during a JDK 7 refactor. Combined with `sun.awt.SunToolkit.getField()` (a confused deputy calling `doPrivileged` + `setAccessible(true)`), an attacker overwrites the `acc` field of the `Statement` with an `AllPermission` AccessControlContext, then invokes `System.setSecurityManager(null)`.

`[snippet:DESER-J011]`

`[citation:DESER-J011]`

---

## 5. JVM Internals

### 5.1 `sun.misc.Unsafe.defineClass()` — Unchecked Class Injection
**Risk:** Loads arbitrary bytecode into any classloader bypassing all SecurityManager checks. Can inject classes into the bootstrap classloader or privileged packages with `AllPermission` protection domain.

`[snippet:JVMI-J001]`

`[citation:JVMI-J001]`

### 5.2 `MethodHandles.Lookup.defineHiddenClass(NESTMATE)` — Nest-Based Access Bypass
**Risk:** Creates a hidden class injected into an existing nest (e.g., `java.lang.invoke`), granting access to all private members of the nest host. The hidden class is invisible to classloaders, reflection, and JVMTI agents.

`[snippet:JVMI-J002]`

`[citation:JVMI-J002]`

### 5.3 HotSpot JIT Shellcode Injection via Unsafe Overwrite
**Risk:** Uses Oop-Klass model offsets to locate JIT-compiled native code address, then overwrites it with arbitrary shellcode via `Unsafe.putByte()`. Executes native machine code directly within the JVM process.

`[snippet:JVMI-J003]`

`[citation:JVMI-J003]`

### 5.4 JNI/JNA Native Code Injection — Complete SecurityManager Bypass
**Risk:** Native code called via JNI operates completely outside the JVM security model. Arbitrary system calls, file I/O, process creation — no SecurityManager check is performed.

`[snippet:JVMI-J004]`

`[citation:JVMI-J004]`

### 5.5 JVMTI Agent Injection — Runtime Bytecode Transformation
**Risk:** JVMTI agents operate at native level, intercepting every class load and redefining already-loaded classes. Dynamically attach via Attach API. Even with `-XX:+DisableAttachMechanism`, tools like `shouganaiyo-loader` can force-attach via Frida.

`[snippet:JVMI-J005]`

`[citation:JVMI-J005]`

### 5.6 JPMS opens Directive → Full Module Privilege Escalation
**Risk:** If a module opens ANY single package to an attacker's module, the attacker can use `Lookup.defineClass()` to inject a class into that opened package. The injected class can call `MethodHandles.lookup()` to obtain a private lookup with full privileged access to ALL packages in the target module.

`[snippet:JVMI-J006]`

`[citation:JVMI-J006]`

---

## 6. CTF & Sandbox Escape

### 6.1 Unsafe Memory Scan → Overwrite SecurityManager Field
**Risk:** Obtain `Unsafe` instance via reflection, get base address of `System.class` statics via `unsafe.staticFieldBase()`, scan memory offsets to find and nullify the SecurityManager pointer. Works on JDK 8.

`[snippet:CTF-J001]`

`[citation:CTF-J001]`

### 6.2 NIO Buffer Integer Overflow → Type Confusion → Sandbox Escape (CVE-2015-4843)
**CTF:** Aperi'CTF 2019 — Java-jail
**Risk:** Integer overflow in NIO buffer classes allows OOB native memory copy between typed arrays, creating type confusion. Attacker confuses a `ClassLoader` into an attacker-controlled `MyClassLoader` reference to call `defineClass()`.

`[snippet:CTF-J002]`

`[citation:CTF-J002]`

### 6.3 GraalVM Espresso Continuation API ROP-like Deserialization
**CTF/Research:** X1r0z / GEEKCON 2025
**Risk:** GraalVM Espresso's Continuation API serializes the entire JVM call stack via `stackFrameHead`. An attacker who controls the deserialized `Continuation` object can forge arbitrary stack frames, hijacking control flow to call `Runtime.exec()` — a ROP-like attack using JDK internal classes (`sun.print.UnixPrintJob`).

`[citation:CTF-J003]`

### 6.4 Proxy + JMX Protected Package Access (ZDI-13-XXX)
**Risk:** Three sub-vulnerabilities chain: (1) `JmxMBeanServer.getMBeanInstantiator().findClass()` loads protected-package classes; (2) `Proxy.getProxyClass()` in bootstrap loader leaks Field references; (3) Proxy invocation handler captures Method objects from protected interfaces.

`[citation:CTF-J004]`

### 6.5 Direct SecurityManager Instance Manipulation via Shared Namespace
**CTF:** TJCTF 2016 — Java Sandbox
**Risk:** Custom SecurityManager and untrusted code share the same namespace. Attacker directly references the `CustomSecurityManager` instance and modifies its mutable `allow` field.

`[snippet:CTF-J005]`

`[citation:CTF-J005]`

---

## 7. Protocol & Parser Abuse

### 7.1 java.net.URL vs java.net.URI Fragment-Based Host Confusion
**Risk:** `URI.getHost()` and `URL.getHost()` parse the authority differently when fragments (`#`) are present. Validator using `URI` sees `trusted.internal`; `URL.openConnection()` connects to `evil.com`.

`[snippet:PROTO-J001]`

`[citation:PROTO-J001]`

### 7.2 XInclude-Based XXE — DOCTYPE Filter Bypass
**Risk:** When DOCTYPE is blocked (common XXE mitigation), `XInclude` provides an alternative vector requiring no DOCTYPE — unless `setXIncludeAware(false)` is explicitly called.

`[snippet:PROTO-J002]`
`[snippet:PROTO-J002]`

`[citation:PROTO-J002]`

### 7.3 XSLT Injection via javax.xml.transform — Extension Function RCE
**Risk:** Without `FEATURE_SECURE_PROCESSING`, Xalan/Saxon processors expose `java.lang.Runtime` via extension function namespaces.

`[snippet:PROTO-J003]`

`[citation:PROTO-J003]`

### 7.4 Apache Commons JXPath Expression Injection — Direct RCE (CVE-2022-41852)
**Risk:** `JXPathContext.getValue()` evaluates XPath expressions that can include arbitrary Java static method calls via extension functions. No gadget chain needed.

`[snippet:PROTO-J004]`

`[citation:PROTO-J004]`

### 7.5 JavaMail / Apache MIME4J Email Header Injection
**Risk:** JavaMail `InternetAddress` and MIME4J `RawField` historically accepted CRLF characters in header values, allowing header injection.

`[snippet:PROTO-J005]`

`[citation:PROTO-J005]`

### 7.6 HttpURLConnection Automatic Redirect Following → Open Redirect to SSRF
**Risk:** `HttpURLConnection` follows redirects by default for GET requests. If user-controlled URLs are validated only on the initial host, following redirects leads to SSRF.

`[snippet:PROTO-J006]`

`[citation:PROTO-J006]`

### 7.7 javax.crypto.Cipher RSA Timing Oracle (Marvin Attack / Bleichenbacher)
**Risk:** JCE `Cipher` API throws `BadPaddingException` when RSA PKCS#1 v1.5 decryption fails — creating an inherent timing side channel. This is a DESIGN flaw in the JCE API, not an implementation bug.

`[snippet:PROTO-J007]`

`[citation:PROTO-J007]`

---

## 8. Framework & ORM Sinks

### 8.1 Thymeleaf Triple-Bypass SSTI Sandbox Escape (CVE-2026-40478)
**Risk:** Three chained bypasses defeat Thymeleaf's expression sandbox: (1) TAB (0x09) bypasses the normalize-based keyword scanner; (2) `__|...|__` preprocessing evades expression detection; (3) Jackson/Spring Core classes evade the ACL blocklist.

`[snippet:FWK-J001]`

`[citation:FWK-J001]`

### 8.2 Spring Cloud Gateway SpEL Injection Bypass (CVE-2025-41243)
**Risk:** After CVE-2022-22947 was fixed by switching to `RestrictivePropertyAccessor`, a bypass was found: the `@systemProperties` bean was modifiable — attacker disables the sandbox from within, then accesses full `StandardEvaluationContext`.

`[snippet:FWK-J002]`

`[citation:FWK-J002]`

### 8.3 Spring Properties → Logback JNDI Injection → RCE
**Risk:** Limited file write (`.xml`) allows planting `application.xml` that sets `logging.config` to attacker URL, forcing Logback to fetch remote `logback.xml` with `<insertFromJNDI>`.

`[snippet:FWK-J003]`

`[citation:FWK-J003]`

### 8.4 Hibernate HQL Breakout — DB-Specific SQL Escape Techniques
**Risk:** HQL injection via string concatenation allows breaking out into native SQL using DB-specific parser differentials between Hibernate and the underlying database.

`[snippet:FWK-J004]`

`[citation:FWK-J004]`

### 8.5 MyBatis OGNL RCE via @SelectProvider (CVE-2020-26945)
**Risk:** When user-controlled input reaches `${}` in MyBatis dynamic SQL, `OgnlCache.getValue()` evaluates OGNL expressions. MyBatis 3.5.4+ blacklists `Runtime` but other dangerous classes remain reachable.

`[snippet:FWK-J005]`

`[citation:FWK-J005]`

### 8.6 Spring Data MongoDB SpEL Injection (CVE-2022-22980)
**Risk:** Repository methods with `@Query` using `?#{?0}` parameter syntax evaluate user input in `StandardEvaluationContext` — leading to SpEL injection.

`[snippet:FWK-J006]`

`[citation:FWK-J006]`

### 8.7 JNDI MemoryUserDatabaseFactory Path Traversal to JSP Shell
**Risk:** `MemoryUserDatabaseFactory` writes attacker-controlled XML to arbitrary files via path traversal in `pathname`. Combined with `BeanFactory` + `FileUtil.mkdir` to bypass `isWriteable()` check. Writes JSP webshell.

`[snippet:FWK-J007]`

`[citation:FWK-J007]`

### 8.8 Spring AI SpEL Injection (CVE-2026-22738)
**Risk:** Brand new attack surface — Spring AI's vector store filter keys are concatenated into SpEL expressions with `StandardEvaluationContext`. User-supplied filter keys achieve RCE.

`[snippet:FWK-J008]`

`[citation:FWK-J008]`

---

## 9. Numeric & Type Edge Cases

### 9.1 Integer Overflow in Array Buffer Allocation (CVE-2023-34453/34454)
**Risk:** Unchecked multiplication leads to undersized buffer allocation and OOB access. `snappy-java` compressed with `int[]` input where `length * 4` overflows.

`[snippet:NUM-J001]`

`[citation:NUM-J001]`

### 9.2 Narrow Cast / Integer Truncation Auth Bypass
**Risk:** A `long` user ID passes validation, then narrows to `int` wrapping to a different user's ID — auth bypass.

`[snippet:NUM-J002]`

`[citation:NUM-J002]`

### 9.3 BigDecimal CPU Exhaustion via Scientific Notation
**Risk:** `new BigDecimal("5e912345")` creates ~1M decimal digits. Operations on it consume 100% CPU for minutes. Known since JDK-6560193 (2006) — unfixed.

`[snippet:NUM-J003]`

`[citation:NUM-J003]`

### 9.4 String.hashCode Collision DoS — Custom Key Comparable Bypass
**Risk:** Java's `String.hashCode()` (multiplier 31, DJBX33A) has trivial collision generation. Java 8+ HashMap treeification only works if key implements `Comparable` — custom keys without it remain O(n).

`[snippet:NUM-J004]`

`[citation:NUM-J004]`

### 9.5 NaN/Infinity Injection Bypassing Input Validation
**Risk:** `Double.valueOf("NaN")` and `Double.valueOf("Infinity")` create exceptional values. NaN comparison always returns false (breaking `equals()`), and Infinity bypasses range checks.

`[snippet:NUM-J005]`

`[citation:NUM-J005]`

### 9.6 ZIP Slip Partial Path Traversal via startsWith() (CVE-2023-28465)
**Risk:** The most common "fix" for ZIP Slip uses `String.startsWith()` — which performs string prefix matching, not path component comparison. `/usr/outnot` matches `startsWith("/usr/out")`.

`[snippet:NUM-J006]`

`[citation:NUM-J006]`

---

## 10. Bleeding-Edge CVEs (2024–2026)

### 10.1 CVE-2025-24813 — Tomcat Partial PUT + Session Deserialization RCE
**Risk:** Path-equivalence (internal dot) combines with deserialization. Partial PUT creates temp files from URL paths. If file-based session persistence is enabled, attacker uploads `.session` file via partial PUT, then triggers deserialization via `JSESSIONID=.[filename]`.

`[snippet:CVE-J001]`

`[citation:CVE-J001]`

### 10.2 CVE-2025-11226 — Logback ACE via Conditional Config Processing
**Risk:** Logback's `<if>` conditional configuration evaluates Janino expressions. The `new` operator enables arbitrary Java object instantiation from config.

`[snippet:CVE-J002]`

`[citation:CVE-J002]`

### 10.3 CVE-2025-50059 — JDK HTTP Client Access Control Bypass
**Risk:** JDK built-in HTTP client (`java.net.http`) improper header handling allows access to data across security boundaries.

`[citation:CVE-J003]`

### 10.4 CVE-2025-53066 — JDK JAXP XXE / Information Disclosure
**Risk:** JAXP perennial attack surface — improper XML input handling allows unauthenticated attackers to access all accessible data.

`[citation:CVE-J004]`

### 10.5 CVE-2025-30749 — JDK Glyph Rendering Deserialization RCE
**Risk:** Deserialization in the font/glyph rendering pipeline — an unusual sink rarely considered a security boundary.

`[citation:CVE-J005]`

### 10.6 CVE-2026-42779 — Apache MINA Deserialization Filter Bypass
**Risk:** `forClass()` returning null completely skips the `acceptMatchers` allowlist — all gadget chain classes bypass the filter via type-0 class descriptors.

`[snippet:CVE-J006]`

`[citation:CVE-J006]`

### 10.7 CVE-2026-33701/728 — APM Agent RMI Deserialization (OpenTelemetry / Datadog)
**Risk:** Observability agents unknowingly opened deserialization RMI endpoints. Both OpenTelemetry and Datadog had the same bug — RMI instrumentation deserialized incoming data without serialization filters.

`[citation:CVE-J007]`

### 10.8 CVE-2026-33439 — OpenAM Pre-Auth Deserialization via jato.clientSession
**Risk:** After CVE-2021-35464's fix applied `WhitelistObjectInputStream` to `jato.pageSession`, the *other* serialization parameter `jato.clientSession` was left unmitigated. Pre-authentication RCE.

`[citation:CVE-J008]`

### 10.9 JVM Container Detection Silent Fallback to Host Limits (JDK-8346874)
**Risk:** On Linux kernel 6.12+, JVM's cgroup v2 detection code fails because it reads `/proc/cgroups` (deprecated for v2). JVM silently falls back to host CPU/memory — causing OOM in containers. No indication except `-Xlog:os+container=trace`.

`[citation:CVE-J009]`

### 10.10 ECDHKeyAgreement Key Confusion via Stale State (JDK-8320449)
**Risk:** `ECDHKeyAgreement.init()` with invalid key leaves prior private/public keys intact. Subsequent `doPhase()` uses stale keys — computing shared secret with wrong private key. Combined with invalid curve attacks this leaks key material.

`[citation:CVE-J010]`

---

---

