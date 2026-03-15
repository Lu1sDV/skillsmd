# .NET / C# Sinks

---

## RCE

`Process.Start()`, `CodeDom.Compiler`, Roslyn `CSharpScript.EvaluateAsync()`, `PowerShell.Create().AddScript()`, `Assembly.Load()` + reflection

---

## Deserialization

`BinaryFormatter.Deserialize()`, `ObjectStateFormatter.Deserialize()`, `NetDataContractSerializer.ReadObject()`, `SoapFormatter.Deserialize()`, `LosFormatter.Deserialize()`, `XmlSerializer` with known types, `Json.NET JsonConvert.DeserializeObject()` with `TypeNameHandling != None`, `JavaScriptSerializer` with `SimpleTypeResolver`, `DataContractSerializer` with known types, `ActivitySurrogateSelector` — use ysoserial.net

---

## SSRF

`HttpClient.GetAsync()`, `WebClient.DownloadString()`, `HttpWebRequest`, `WebRequest.Create()`, `RestSharp`

---

## Additional .NET Sinks

- **SQLi:** `SqlCommand` with string concat, `Entity Framework` `FromSqlRaw()` / `ExecuteSqlRaw()` with interpolation, `Dapper` `Query()` with string concat
- **XXE:** `XmlDocument.Load()` with `XmlResolver` set, `XmlReader.Create()` without `DtdProcessing.Prohibit`, `XDocument` in older .NET
- **Path Traversal:** `System.IO.File.ReadAllText(userInput)`, `Path.Combine()` (does NOT prevent `..`), `FileStream` with unsanitized path
- **XSS:** `@Html.Raw()` in Razor, `HttpUtility.HtmlEncode()` missing, `Response.Write()` with user input
- **LDAP:** `DirectorySearcher.Filter` with string concat, `DirectoryEntry` with unsanitized path

---

## SOAPwn — .NET HttpWebClientProtocol File Write (CVE-2025-34392)

`SoapHttpClientProtocol` and related .NET HTTP client proxy classes use `WebRequest.Create(url)` which returns different types based on URL scheme:

**Exploit chain:**
1. `WebRequest.Create("file:///path/shell.aspx")` returns `FileWebRequest` (not `HttpWebRequest`)
2. Invalid cast does NOT throw — proxy writes SOAP request body to filesystem
3. Attacker controls URL, file path, and SOAP body content via WSDL
4. Arbitrary file write → ASPX/CSHTML webshell → RCE
5. UNC paths (`\\attacker\share`) enable NTLM relay

**Affected sinks:**
- `SoapHttpClientProtocol` (auto-generated WSDL proxy classes)
- `ServiceDescriptionImporter` (dynamic WSDL import)
- Any code calling `WebRequest.Create()` with user-controlled URL scheme

**CVSS 10.0** — Microsoft declined to patch .NET Framework.

**Confirmed affected products:** Barracuda RMM, Ivanti EPM, Umbraco 8, PowerShell, MSSQL SSIS.

Source: watchTowr Labs, 2025.
