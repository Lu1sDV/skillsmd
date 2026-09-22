# Ruby Sinks

---

## RCE

`system()`, `exec()`, `` `command` `` (backticks), `%x(command)`, `IO.popen()`, `Open3.capture2/capture3/popen3()`, `Kernel.send()`, `eval()`, `instance_eval()`, `class_eval()`, `ERB.new(user_input).result`, `Kernel.open()` (with `|command` prefix!)

---

## Deserialization

`Marshal.load()`, `YAML.load()` / `Psych.load()` (with `!!ruby/object:` gadgets), `Oj.load()` with unsafe mode, `JSON.parse()` with `create_additions: true`

---

## SSRF

`Net::HTTP`, `open-uri` (`URI.open()`), `HTTParty`, `Faraday`, `RestClient`, `Typhoeus`, `Excon`

---

## Additional Ruby Sinks

- **SQLi:** ActiveRecord `where("col = '#{params[:x]}'")`, `order(user_input)`, `group()`, `having()`, `pluck()`, `calculate()`, `find_by_sql()`
- **XSS:** `raw()` helper, `html_safe` on user input, `content_tag` with unsanitized attributes
- **Path Traversal:** `File.read(user_input)`, `File.open()`, `send_file()` without path validation, `Pathname.new(user_input)`
- **Open redirect:** `redirect_to(params[:url])` without validation
