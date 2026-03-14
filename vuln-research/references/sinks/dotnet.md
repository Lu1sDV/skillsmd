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
