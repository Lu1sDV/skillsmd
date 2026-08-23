# Ruby / Rails Security-Sensitive API Corpus

Minimal descriptions of high-risk Ruby and Ruby on Rails APIs, including terminal sinks and the sources, propagators, sanitizers, guards, and configuration patterns needed to model them in taint analysis, fuzzing, SAST rule writing, and bypass research.

Scope: Ruby 2.x/3.x, Rails 3.x-7.x/8.x era applications, common gems, and framework configuration patterns. Treat examples that mention `params`, request headers, cookies, session data, uploaded files, queue payloads, cache values, or database-controlled strings as tainted-data patterns.

---

## Sink type: Code evaluation & metaprogramming

- `eval` – Evaluate an arbitrary string as Ruby code.
- `Kernel.eval` – Fully qualified `eval` call, same risk.
- `binding.eval` / `Binding#eval` – Evaluate in a specific binding/scope.
- `TOPLEVEL_BINDING.eval` – Evaluate code in the top-level object scope.
- `instance_eval` – Evaluate code in the context of an object.
- `class_eval` – Evaluate code in the context of a class.
- `module_eval` – Evaluate code in the context of a module.
- `instance_exec` – Execute an existing block in the context of an object; it does not evaluate a source string.
- `class_exec` – Execute an existing block in the context of a class; it does not evaluate a source string.
- `module_exec` – Execute an existing block in the context of a module; it does not evaluate a source string.
- `RubyVM::InstructionSequence.compile(code).eval` – Compile and execute Ruby code.
- `RubyVM::InstructionSequence.load_from_binary(data).eval` – Execute serialized Ruby bytecode where available.
- `ERB.new(template).result(binding)` – Evaluate Ruby embedded in a template string.
- `ERB.new(params[:template]).result` – Template source and code are data-controlled.
- `Haml::Engine.new(template).render` – Render tainted Haml template source.
- `Slim::Template.new { template }.render` – Render tainted Slim template source.
- `Tilt.new(path_or_template).render` – Dispatch to template engines from tainted path/source.
- `Liquid::Template.parse(template).render(...)` – Evaluate a template with Liquid filters, drops, and registered tags; risk depends on the exposed environment.
- `define_method` – Define a method dynamically, often from interpolated names or code-producing blocks.
- `define_singleton_method` – Define per-object methods dynamically.
- `send` – Dynamic dispatch to a method name from data.
- `__send__` – Alias of `send`, sometimes used to bypass filters.
- `public_send` – Dynamic dispatch to public methods; still dangerous with tainted names.
- `method(name).call` – Indirect call using a looked-up method object.
- `respond_to_missing?` paired with `method_missing` – Makes custom dynamic dispatch look legitimate to callers.
- `def_delegators(:@target, *tainted_names)` / `delegate(*tainted_names, to: :target)` – Runtime delegation from attacker-controlled method names can overwrite security-sensitive methods.
- `Object.const_get` – Resolve a constant by name from data.
- `Module.const_get` – Resolve constants within a module.
- `Kernel.const_get(params[:klass])` – Alternative constant lookups from params.
- `Object.const_set` – Create constants dynamically from names.
- `remove_const` – Remove constants dynamically from names.
- `autoload(name, path)` – Lazy-load a constant from a data-derived path.
- `ObjectSpace.each_object` – Introspect loaded objects, useful for gadget discovery.
- `Kernel.load(path)` / `load(path)` – Load and execute external Ruby file at runtime.
- `Kernel.require(feature)` / `require(feature)` – Load a library based on a data-derived path/name.
- `Kernel.require_relative(path)` / `require_relative(path)` – Relative load influenced by directory and data.
- `Thread.new { eval(...) }` – Eval inside thread, same sink in a different execution context.
- `Object#method_missing` – Custom dynamic dispatch based on method name.
- `BasicObject#method_missing` – Minimal-base dynamic dispatch.
- `ActiveSupport::Inflector.constantize` – Convert string to class constant and use it.
- `ActiveSupport::Inflector.safe_constantize` – Safer nil-returning variant, still reflection from strings.
- `"User".constantize` – Typical pattern resolving a model class by name.
- `params[:klass].constantize` – User-controlled class resolution pattern.
- `params[:klass].constantize.new(params[:arg])` – Class and constructor arguments both influenced by input.
- `params[:klass].constantize.send(params[:method], *params[:args])` – Fully data-driven reflection call.
- `Pathname.method(params[:method])` – Reflective calls on `Pathname` from data.
- `Logger.method(params[:method])` – Reflective calls on `Logger` from data.
- `Fiddle.dlopen(path)` – Load native libraries from a path.
- `Fiddle::Function.new(ptr, args, ret).call` – Invoke native functions through Fiddle.
- `FFI::Library#ffi_lib(path)` – Load native libraries through the `ffi` gem.
- `DL.dlopen(path)` – Legacy native library loading where present.
- `Rake::Task[params[:task]].invoke` – Dynamic task dispatch.
- `Thor` command dispatch from request data – CLI command objects exposed to web/queue inputs.

---

## Sink type: OS command execution

- Backticks `` `cmd` `` – Execute shell command and capture output.
- `%x[cmd]` – Backtick equivalent using `%x` literal.
- `Kernel.system("cmd")` / `system("cmd")` – Execute shell command in subshell.
- `Kernel.system("cmd #{user}")` – Interpolated command string.
- `Kernel.system(cmd, arg1, arg2)` – Argument-vector form avoids shell parsing but still permits attacker-chosen executables, arguments, and option injection; keep the executable fixed and use `--` where supported.
- `Kernel.exec("cmd")` / `exec("cmd")` – Replace current process with command.
- `Kernel.spawn("cmd")` / `spawn("cmd")` – Spawn subprocess with shell command.
- `Process.exec("cmd")` – Process-level exec, same effect.
- `Process.spawn("cmd")` – Process-level spawn, same effect.
- `Process.fork { system("cmd") }` – Child process executing shell commands.
- `IO.popen("cmd")` – Run a command and open IO to it.
- `IO.popen(["cmd", "arg"])` – Arg-array form, still command execution.
- `PTY.spawn("cmd")` – Spawn a command attached to a pseudo-terminal.
- `Open3.popen2("cmd")` – Execute command, capture stdin/stdout.
- `Open3.popen2e("cmd")` – Execute with combined stdout/stderr.
- `Open3.popen3("cmd")` – Execute with stdin/stdout/stderr pipes.
- `Open3.capture2("cmd")` – Run command and capture stdout plus status.
- `Open3.capture2e("cmd")` – Capture stdout and stderr merged.
- `Open3.capture3("cmd")` – Capture stdout, stderr, and status.
- `Open3.pipeline("cmd1", "cmd2")` – Shell-style pipelines between commands.
- `Open3.pipeline_r(...)` – Pipeline with reading end.
- `Open3.pipeline_w(...)` – Pipeline with writing end.
- `Open3.pipeline_rw(...)` – Pipeline with read/write ends.
- `Open3.pipeline_start(...)` – Start pipeline asynchronously.
- `open("|cmd")` – `open` with leading pipe spawns a process.
- `IO.read("|cmd")` – Read from command via pipe path.
- `IO.readlines("|cmd")` – Read all lines from command via pipe path.
- `IO.foreach("|cmd")` – Iterate over command output via pipe path.
- `URI.open("|cmd")` – OpenURI variant executing command for pipe paths in vulnerable call chains.
- `Logger.new("|cmd")` – Logger path starting with pipe may run a command on vulnerable Ruby versions/configurations.
- `Logger#reopen("|cmd")` – Reopen logger to a command pipe.
- `Gem::Source::Git#rev_parse` – Gadget that runs `git` via `IO.popen`.
- `Rake::FileUtilsExt#sh(cmd)` / `sh(cmd)` – Rake shell helper.
- `Thor::Actions#run(cmd)` – Thor shell helper.
- `Mixlib::ShellOut.new(cmd).run_command` – Chef ecosystem command wrapper.
- `Terrapin::CommandLine.new(...).run` – Command wrapper used by older processing stacks.
- `Cocaine::CommandLine.new(...).run` – Command wrapper used by older Paperclip/ImageMagick stacks.
- `MiniMagick::Tool::*` and MiniMagick processing methods – Invoke external ImageMagick tools with tainted paths/options.
- `ImageProcessing::MiniMagick.source(file).call` – ImageMagick-backed processing of tainted files/options.
- Paperclip processors and validations invoking ImageMagick – File name/options may reach shell or delegate commands.
- `system("convert #{file}")` – Typical image-processing RCE pattern.
- `system("ffmpeg -i #{file}")` – Typical media-processing RCE pattern.
- Shelling out to `tar`, `unzip`, `7z`, `git`, `curl`, `wget`, `openssl`, `gs`, `convert`, `identify`, `ffmpeg`, `pandoc`, or `wkhtmltopdf` with tainted paths/options – Wrapper command injection and parser attack surface.

---

## Sink type: Unsafe deserialization and object materialization

- `Marshal.load(data)` – Deserialize arbitrary Ruby objects from data.
- `Marshal.restore(data)` – Equivalent unsafe deserialization.
- `YAML.load(yaml)` – Load YAML and instantiate arbitrary objects on unsafe versions/configurations.
- `YAML.unsafe_load(yaml)` – Explicit unsafe YAML object deserialization.
- `YAML.load_file(path)` – File-based YAML deserialization.
- `YAML.unsafe_load_file(path)` – Explicit unsafe file-based YAML deserialization.
- `YAML.load_stream(yaml)` – Multiple YAML documents load.
- `Psych.load(yaml)` – YAML engine load; unsafe on older versions/configurations.
- `Psych.unsafe_load(yaml)` – Explicit unsafe Psych object loading.
- `Psych.load_file(path)` – Psych version of YAML file loader.
- `Psych.unsafe_load_file(path)` – Explicit unsafe Psych file loader.
- `Psych.load_stream(yaml)` – Multi-document Psych loader.
- `Psych.safe_load(yaml, permitted_classes: ...)` – Dangerous when permitted classes are broad or user-influenced.
- `Psych.safe_load(yaml, aliases: true)` – Alias expansion can enable resource exhaustion and unsafe graph shapes.
- `JSON.load(json)` – JSON deserialization with custom object hooks.
- `JSON.parse(json, create_additions: true)` – Instantiate objects via JSON additions.
- `Oj.load(json, mode: :object)` – Oj object mode creates arbitrary classes.
- `Oj.load(json)` – Oj generic load with unsafe global/default config.
- `Oj.object_load(data)` – Direct object load.
- `Oj.compat_load(json)` – Compatibility mode may instantiate objects depending on options.
- `Ox.parse_obj(xml)` – Ox object deserialization from XML.
- `Ox.load(xml, mode: :object)` – Ox load in object mode.
- `Plist.parse_xml(xml, marshal: true)` – Plist parsing that uses Marshal internally.
- `ActiveSupport::JSON.decode(json)` – Old versions or custom handlers creating objects.
- `ActiveSupport::MessagePack.decode(data)` – MessagePack decode with custom types.
- `ActiveRecord::Coders::YAMLColumn` – YAML-backed model attribute deserialization.
- `serialize :attr` with YAML/Marshal coders – Model attribute materialization from database/cache data.
- `Rails.application.config.active_record.use_yaml_unsafe_load = true` – Re-enables unsafe YAML loading in ActiveRecord.
- `ActiveSupport::MessageVerifier#verify` – Signed payload materialization; dangerous with Marshal serializer or leaked/weak secret.
- `ActiveSupport::MessageEncryptor#decrypt_and_verify` – Encrypted signed payload materialization; dangerous with Marshal serializer or leaked/weak secret.
- `Rails.application.config.action_dispatch.cookies_serializer = :marshal` – Session/cookie values serialized with Marshal.
- `Rails.application.config.action_dispatch.cookies_serializer = :hybrid` – Hybrid migration mode may still accept Marshal cookies.
- `PStore.new(path)` / `PStore#transaction` – Marshal-backed storage; unsafe if file path/content is attacker-controlled.
- `DRb.start_service(uri, object)` – Exposes Ruby object methods over distributed Ruby RPC.
- `DRbObject.new_with_uri(uri)` – Connects to remote DRb objects and invokes methods.
- `GlobalID::Locator.locate(gid)` – Materializes application records from data-controlled GlobalIDs.
- `GlobalID::Locator.locate_signed(gid)` – Signed GlobalID lookup; still an object-access sink when secret or purpose boundaries are weak.
- `ActiveSupport::Deprecation::DeprecatedInstanceVariableProxy#method_missing` – Gadget method auto-invoked.
- `ActiveSupport::Deprecation::DeprecatedInstanceVariableProxy#instance_variable_get` – Gadget access method.
- `Gem::Requirement#hash` – Gadget method called during Hash key reconstruction.
- `Puma::MiniSSL::Context#key_password` – Gadget method in SSL context.
- Custom `marshal_load` – Any `#marshal_load` defined in app/gems.
- Custom `yaml_initialize` – Any YAML lifecycle hook implementing logic.
- Custom `init_with(coder)` – Psych/YAML lifecycle hook.
- Custom `json_create` – JSON additions object hook.
- `ActiveStorage` signed blob decode that feeds `Marshal.load` – Insecure deserialization pattern in custom/legacy integrations.
- `Rails.cache.read` with Marshal backend – Reading deserialized entries from untrusted or attacker-writable cache.
- Controller `session` / `request.session` with a Marshal-capable cookie serializer – Reading the session can materialize attacker-controlled objects when integrity or secret boundaries fail.
- `Delayed::Job` YAML handler deserialization – Job payload storage deserializes YAML-encoded handlers.
- Sidekiq/ActiveJob argument deserialization of GlobalID records – Queue-controlled object lookup and authorization boundary sink.

---

## Sink type: File system, path traversal, file uploads

Path constructors and uploaded-file metadata below are sources or propagators; filesystem methods that read, write, move, or delete are terminal sinks.

- `File.read(path)` – Read file contents based on tainted path.
- `File.binread(path)` – Binary file read.
- `File.readlines(path)` – Read all lines from file.
- `File.foreach(path)` – Iterate through lines of file.
- `File.open(path, mode)` – Open file for reading or writing.
- `File.new(path, mode)` – Create or open a file.
- `File.write(path, data)` – Write arbitrary data to path.
- `File.binwrite(path, data)` – Binary write to path.
- `File.delete(path)` – Delete file at path.
- `File.unlink(path)` – Remove file at path.
- `File.rename(old, new)` – Rename or move files.
- `File.chmod(mode, path)` – Change permissions on file.
- `File.chown(owner, group, path)` – Change ownership of file.
- `File.symlink(target, link)` – Create symlink.
- `File.lstat(path)` – Stat potentially sensitive path.
- `File.stat(path)` – Follow symlinks and stat path.
- `File.truncate(path, length)` – Truncate a file based on path.
- `File.join(base, params[:path])` – Path propagator that does not by itself prevent `..` traversal; no filesystem access occurs here.
- `Rails.root.join(params[:path])` – Path propagator requiring canonicalization and prefix checks before a filesystem operation.
- `Pathname.new(path)` – Path wrapper and propagator; access occurs only when an I/O method is called.
- `Pathname#join(user_path)` / `Pathname#+` – An absolute component discards the preceding base path; canonical containment checks remain required.
- `Pathname#read` – Read path contents.
- `Pathname#binread` – Binary read.
- `Pathname#open` – Open path contents.
- `Pathname#write` – Write path contents.
- `Pathname#delete` – Delete file via Pathname.
- `Pathname#children` / `#each_child` – Directory listing from tainted path.
- `IO.read(path)` – IO file read wrapper.
- `IO.binread(path)` – Binary IO read.
- `IO.readlines(path)` – IO multiple-line read.
- `IO.foreach(path)` – IO line iteration.
- `IO.write(path, data)` – IO write to path.
- `IO.binwrite(path, data)` – Binary IO write to path.
- `Dir.glob(pattern)` – Glob expansion exposing directory contents.
- `Dir[pattern]` – Shorthand glob call.
- `Dir.foreach(path)` – Iterate directory entries.
- `Dir.children(path)` / `Dir.entries(path)` – Directory listing.
- `Dir.chdir(dir)` – Change working directory based on input.
- `Dir.mkdir(path)` / `Dir.rmdir(path)` – Create/remove directories from tainted paths.
- `Dir.mktmpdir(prefix, dir)` – Create temporary directory with tainted prefix/location.
- `FileUtils.rm(path)` – Remove file or directory.
- `FileUtils.rm_rf(path)` – Recursive delete based on tainted path.
- `FileUtils.mv(src, dest)` – Move/rename files and directories.
- `FileUtils.cp(src, dest)` – Copy files and directories.
- `FileUtils.cp_r(src, dest)` – Recursive copy.
- `FileUtils.mkdir(path)` / `FileUtils.mkdir_p(path)` – Create directories based on tainted path.
- `FileUtils.chmod(mode, path)` / `FileUtils.chown(owner, group, path)` – Permission/ownership changes.
- `FileUtils.ln_s(target, link)` – Create symlink via FileUtils.
- `Tempfile.new(prefix, dir)` – Create temp files in attacker-influenced directory.
- `Tempfile.open(prefix, dir)` – Open temp file.
- `Tempfile.create(prefix, dir)` – Create temp file.
- `Tempfile#write(data)` – Write user content to temp file.
- `Tempfile#puts(data)` – Put data into temp file.
- `Tempfile#<< data` – Append data to temp file.
- `Tempfile#close` – Lifecycle boundary before external processing; not a path sink by itself.
- `Tempfile#unlink` – Cleanup operation targeting the tempfile, not an arbitrary attacker-selected path.
- `ActionDispatch::Http::UploadedFile#original_filename` – Taint source often misused in paths and headers.
- `params[:file].path` / `UploadedFile#path` – Temporary uploaded file path passed to parsers/processors.
- `send_file(path)` – Rails helper to send files from path.
- `send_data(data, filename:)` – Rails helper sending data as download; filename/content type are additional header/browser sinks.
- `render file: path` – Render file based on filesystem path.
- `prepend_view_path(path)` / `append_view_path(path)` – Dynamic template lookup path.
- `ActiveStorage::Blob.create_and_upload!` – Trusting uploaded filename/content type/metadata.
- `ActiveStorage::Blob#open` / `#download` – Blob content flowing into filesystem or parsers.
- ActiveStorage variants/previews – ImageMagick/Vips/ffmpeg-backed processing of tainted files/options.

---

## Sink type: Archive extraction and decompression

- `Zip::File.open(path)` – Open attacker-controlled ZIP archives.
- `Zip::Entry#extract(dest)` – Extract ZIP entries; Zip Slip if `entry.name` is not canonicalized.
- `Zip::InputStream.open(path)` – Stream ZIP entries with attacker-controlled names/content.
- `Gem::Package::TarReader.new(io)` – Iterate TAR entries with attacker-controlled paths.
- `entry.full_name` from `Gem::Package::TarReader` – Taint source for a TAR path later used during extraction.
- `Gem::Package::TarReader::Entry#file?` / `#symlink?` – Entry-type guards; skipping only directories still permits symbolic-link entries.
- `Archive::Tar::Minitar.unpack(src, dest)` / `Minitar.unpack` – TAR extraction helper.
- `Zlib::GzipReader.open(path)` / `Zlib::GzipReader#read` – Decompression bomb sink.
- `Zlib::Inflate.inflate(data)` – Decompression bomb sink.
- `Bzip2`, `LZMA`, or `Zstd` gem decompression of tainted data – Resource exhaustion and parser attack surface.
- Archive entries with absolute paths, `..`, symlinks, or hardlinks – Arbitrary file write/delete during extraction.
- Extraction using `File.open` / `FileUtils` while following attacker-controlled symlinks – Symlink race/write sink.
- Shelling out to `tar`, `unzip`, `7z`, or `bsdtar` with tainted archive path, flags, or destination – Command execution and unsafe extraction.

---

## Sink type: HTTP clients, SSRF & URL-based sinks

Client constructors and URI parsers below are propagators; outbound sinks are calls that connect, perform, or send a request.

- `Net::HTTP.start(host, port)` – Open HTTP connection to host.
- `Net::HTTP.get(uri_or_host, path)` – Simple HTTP GET.
- `Net::HTTP.get_response(uri)` – Get full HTTP response.
- `Net::HTTP.new(host, port)` – Construct a client object; no connection is made until a start/request operation.
- `Net::HTTP#request(req)` – Send arbitrary request.
- `Net::HTTP::Get.new(path)` – Construct a GET request object; sending occurs at `Net::HTTP#request`.
- `Net::HTTP::Post.new(path)` – Construct a POST request object; sending occurs at `Net::HTTP#request`.
- `URI.open(url)` – Open HTTP/HTTPS/FTP URLs or local paths; non-URI strings fall back to `Kernel.open`.
- `OpenURI.open_uri(url)` – Equivalent OpenURI call.
- `open(url)` – Kernel/open-uri style URL/file open in legacy code.
- `RestClient.get(url, headers)` – HTTP client library call.
- `RestClient.post(url, payload, headers)` – HTTP POST.
- `RestClient::Request.execute(opts)` – Low-level RestClient request.
- `Faraday.new(url)` – Construct a Faraday connection; request methods such as `#get` perform the network operation.
- `Faraday::Connection#get(path)` – Issue GET.
- `Faraday::Connection#post(path)` – Issue POST.
- `HTTP.get(url)` – HTTP.rb GET.
- `HTTP.post(url, body: ...)` – HTTP.rb POST.
- `HTTParty.get(url)` / `HTTParty.post(url)` – Common HTTP client helpers.
- `Excon.new(url)` – Construct an Excon connection; `Excon::Connection#request` performs the network operation.
- `Excon::Connection#request(opts)` – Excon request.
- `Typhoeus::Request.new(url, options).run` – Construct and perform a Typhoeus HTTP request.
- `Typhoeus.get(url, options)` – Typhoeus GET helper.
- `Patron::Session#base_url=` / `#get` – Patron HTTP client.
- `Curl::Easy.new(url).perform` / `Curl.get(url)` – Perform libcurl-backed requests.
- `Mechanize#get(url)` – Browser-like HTTP client.
- `Down.open(url)` / `Down.download(url)` – Remote download helper.
- `Addressable::URI.parse(url)` – URL parsing/canonicalization that may differ from fetcher behavior.
- `URI.join(base, user_path)` – URL construction with override/userinfo/host confusion risk.
- `Socket.tcp(host, port)` – Raw TCP connection to tainted host/port.
- `TCPSocket.open(host, port)` / `TCPSocket.new(host, port)` – Raw socket egress.
- `UDPSocket#connect(host, port)` – UDP egress.
- `OpenSSL::SSL::SSLSocket` connected to tainted host/port – TLS socket egress.
- `Net::FTP.new(host)` – FTP connections.
- `Net::FTP#connect(host)` – Connect to FTP server.
- `Net::FTP#login(user, password)` – Authenticate to FTP.
- `Net::FTP#getbinaryfile(remote, local)` – Download files via FTP.
- `Net::SMTP.start(host, port)` – SMTP connection to tainted host.
- `Net::LDAP.new(host: host, port: port)` – LDAP connection to tainted host.
- `Redis.new(url: url)` / `Redis.new(host: host)` – Internal service egress and data access.
- `PG.connect(host: host, dbname: ...)` – Database client to tainted host/database.
- `Mysql2::Client.new(host: host, database: ...)` – Database client to tainted host/database.
- `Savon.client(wsdl: url)` – SOAP/WSDL fetch from tainted URL.
- `Wasabi.document(url)` – WSDL/XML fetch from tainted URL.
- Webhook integrations fetching user-supplied callback URLs – SSRF and internal metadata access.
- URL parser bypass inputs feeding fetches – decimal/octal/hex IPs, IPv6, userinfo, DNS rebinding, redirects, protocol smuggling, and mixed parser/fetcher normalization.
- `url.start_with?(trusted_url)` / `URI.parse(url).host.end_with?(trusted_host)` – Insufficient URL allowlists vulnerable to userinfo and sibling-domain confusion.
- Validating a URL but fetching the original unresolved value, or following redirects without revalidation – DNS-rebinding and time-of-check/time-of-use SSRF.

---

## Sink type: Redirects and URL construction

- `redirect_to(url)` – Rails controller redirect with user-controlled URL.
- `redirect_to(params[:url])` – Pattern for open redirect.
- `redirect_back(fallback_location:)` – Redirect to referer or fallback.
- `redirect_back_or_to(url)` – Similar helper in some stacks/Rails versions.
- `redirect_to request.referer` – Referer-driven redirect.
- `redirect_to(params[:url], allow_other_host: true)` – Explicitly allows external redirects.
- `redirect_back_or_to(params[:url], allow_other_host: true)` – External-host redirect opt-in.
- `headers["Location"] = params[:url]` – Manual 3xx location header write.
- `response.location = params[:url]` – Manual redirect target assignment.
- `url_for(options)` – Generate URL from options with controllable host/protocol.
- `url_for(host: params[:host])` – Host poisoning in generated links.
- `default_url_options[:host] = params[:host]` – Global/default URL host influenced by input.
- `polymorphic_url(record)` – Build URL from polymorphic argument.
- `link_to(text, url)` – Link helper; dangerous with `javascript:`, `data:`, raw HTML, or untrusted hosts.
- `button_to(text, url)` – Button helper, same issues as `link_to`.
- `image_tag(url)` – Image helper with external source.
- `stylesheet_link_tag(url)` – Stylesheet link to potentially unsafe host.
- `javascript_include_tag(url)` – Script include from external host.
- Devise `stored_location_for(resource)` / `after_sign_in_path_for` – Login return flow controlled by session/params.
- OmniAuth `omniauth.origin` / `params[:origin]` / `params[:return_to]` – OAuth return URL flow.
- Password reset, invitation, or confirmation links generated from `request.host`, `request.original_url`, `X-Forwarded-Host`, or tainted `default_url_options` – Host header poisoning.

---

## Sink type: SQL & data-layer sinks

- `ActiveRecord::Base.find_by_sql(sql)` – Execute raw SQL string.
- `Model.connection.execute(sql)` – Low-level raw SQL execution.
- `Model.connection.exec_query(sql)` – Raw SQL query.
- `Model.connection.select_all(sql)` – Raw select returning rows.
- `Model.connection.select_one(sql)` – Raw select returning one row.
- `Model.connection.select_value(sql)` – Raw select returning scalar.
- `Model.connection.select_rows(sql)` – Raw select returning row arrays.
- `Model.count_by_sql(sql)` – Raw count SQL.
- `Model.where("... #{user} ...")` – String-interpolated WHERE clause.
- `Model.order("... #{user} ...")` – String-interpolated ORDER BY.
- `Model.reorder("... #{user} ...")` – Raw ORDER BY replacement.
- `Model.group("... #{user} ...")` – String-interpolated GROUP BY.
- `Model.having("... #{user} ...")` – String-interpolated HAVING.
- `Model.from("... #{user} ...")` – String-interpolated FROM clause.
- `Model.update_all("... #{user} ...")` – Raw update with interpolated SQL.
- `Model.delete_all("... #{user} ...")` – Raw delete with interpolated SQL.
- `Model.joins("... #{user} ...")` – Raw JOIN with interpolated SQL.
- `Model.select("... #{user} ...")` – Raw SELECT expressions.
- `Model.reselect("... #{user} ...")` – Raw SELECT replacement.
- `Model.lock("... #{user} ...")` – Raw locking clause.
- `Model.pluck(Arel.sql(user))` – Pluck with unescaped SQL fragment.
- `Arel.sql(user)` – Mark raw SQL as safe for Arel.
- `Arel::Nodes::SqlLiteral.new(user)` – Raw SQL literal node.
- `Arel::Nodes::NamedFunction.new(params[:fn], args)` – Tainted SQL function name.
- `sanitize_sql(user)` – Misused sanitization helper returning raw fragments.
- `sanitize_sql_like(user)` – Misused LIKE escape function around interpolation.
- `where("name LIKE '%#{sanitize_sql_like(user)}%'")` – Escaped LIKE content but still string-built SQL.
- Tainted table, column, database, schema, or `schema_search_path` names – Identifier injection and tenant isolation bypass.
- `Sequel::Database["SELECT #{user}"]` – Sequel raw SQL execution.
- `Sequel::Database#run(sql)` – Sequel direct SQL execution.
- `DB.fetch("SELECT #{user}")` – Sequel raw fetch.
- `PG::Connection#exec(sql)` / `#async_exec(sql)` – PostgreSQL driver raw SQL.
- `Mysql2::Client#query(sql)` – MySQL driver raw SQL.
- `SQLite3::Database#execute(sql)` / `#execute_batch(sql)` – SQLite raw SQL.
- Search/filter DSLs that trust params as column names/operators – Dynamic query builder injection.
- Admin/reporting/migration consoles accepting user SQL fragments – Intentional raw SQL surfaces.

---

## Sink type: Views, templating and XSS

Rails output helpers escape ordinary strings by default unless noted; values already marked HTML-safe can bypass that protection.

- `<%= %>` in ERB – Escaped output; context-dependent sink in JavaScript/CSS/URL/HTML-attribute contexts.
- `<%== %>` in ERB – Explicit unescaped output.
- `raw(string)` – Rails helper to mark string as HTML safe.
- `html_safe` – Mark string as safe and skip escaping.
- `safe_join(array)` – HTML-escape non-safe elements before joining; a sanitizer unless elements were already marked HTML-safe.
- `safe_concat(string)` – Append safe/raw content to output buffer.
- `concat(string)` – Append content to output buffer; context and SafeBuffer state matter.
- `ActiveSupport::SafeBuffer#<<` – Append potentially tainted HTML-safe content.
- `content_tag(:tag, body)` – Escapes ordinary body content by default; dangerous with pre-marked `SafeBuffer` values or disabled escaping.
- `tag(:tag, options)` – Escapes ordinary attribute values by default; URL schemes and pre-marked safe values remain context-sensitive.
- `link_to(body, url)` – Renders anchor with content and href.
- `button_to(body, url)` – Renders form + button to URL.
- `image_tag(url)` – Renders image tag with URL.
- `javascript_include_tag(url)` – Include JavaScript from URL.
- `stylesheet_link_tag(url)` – Include CSS link tag.
- `javascript_tag(code)` – Embed JavaScript inside `<script>` tags.
- `render inline: template` – Render inline template string.
- `render :inline => template` – Legacy inline render.
- `render html: value` – HTML response rendering; dangerous with tainted `html_safe`/SafeBuffer values.
- `render file: path` – Render file based on filesystem path.
- `render partial: name` – Render partial from dynamic name.
- `render template: name` – Render template from dynamic name.
- `render layout: params[:layout]` – Dynamic layout selection.
- `render params[:template]` – Dynamic template name resolution pattern.
- `render json: object` – Serialize a JSON response; not an HTML/XSS sink unless the output is embedded into executable HTML/JavaScript or exposed through JSONP.
- `render json: object, callback: params[:callback]` – JSONP callback injection.
- `render xml: object` – XML render, potential injection.
- `render js: code` – JavaScript response rendering.
- `render plain: body, content_type: "text/html"` – Plain/body rendering with attacker-controlled content type.
- `send_data(data, type: "text/html")` – Download/body rendered as active HTML.
- `sanitize(html)` – Sanitizer, misconfigurable.
- `sanitize(html, tags: params[:tags], attributes: params[:attrs], protocols: params[:protocols])` – User-controlled sanitizer policy.
- `strip_tags(html)` – Remove tags but not necessarily safe in all contexts.
- `strip_links(html)` – Remove links, context still dangerous.
- `simple_format(text, {}, sanitize: false)` – Simple formatting with escaping disabled.
- `j(object)` / `escape_javascript(object)` – Escape for JavaScript; misuse or wrong context leads to XSS.
- `to_json` on user-supplied data in `<script>` context – Context-sensitive XSS sink.
- `I18n.t(key)` for `_html` keys – Rails marks some translation keys as HTML-safe.
- `I18n.t("key_html", name: tainted)` – Rails escapes ordinary interpolation values; risk requires attacker-controlled translation content or a value already marked HTML-safe.
- Markdown/CommonMark renderers returning HTML – `Redcarpet`, `Kramdown`, `CommonMarker`, `RDiscount` without sanitization.
- `ActionText::Content.new(html)` / rich-text rendering – Stored HTML/rich-text sanitizer boundary.
- Client-side template helpers fed by Rails views – `data-*`, JSON script tags, Turbo Stream actions, and Stimulus values with untrusted content.

---

## Sink type: Mass assignment & parameter handling

- `User.new(params[:user])` – Rails 3 style mass assignment.
- `User.create(params[:user])` – Mass assignment on create.
- `User.create!(params[:user])` – Strict mass assignment on create.
- `user.update_attributes(params[:user])` – Update via mass assignment.
- `user.update_attributes!(params[:user])` – Strict update via mass assignment.
- `user.update(params[:user])` / `update(params[:model])` – Pass params hash direct to update.
- `user.update!(params[:user])` – Strict direct update.
- `user.assign_attributes(params[:user])` – Assign attributes from params.
- `User.update(params[:id], params[:user])` – Class-level bulk update.
- `User.create!(params)` – Entire params hash passed to model.
- `User.new(params, without_protection: true)` – `protected_attributes` override.
- `User.create(params, without_protection: true)` – Mass assignment ignoring protection.
- `User.new(params, as: :admin)` – Role-based mass assignment.
- `params.permit!` – Strong parameters call permitting all keys.
- `params.require(:user).permit(:admin, :role, ...)` – Permitting sensitive flags.
- `params.to_unsafe_h` / `params.to_unsafe_hash` – Bypass strong parameters to full hash.
- `params[:key]` consumed as a scalar without type enforcement – Rails query syntax can supply arrays or hashes; `permit(:key)` rejects non-scalar shapes.
- `Model#attributes = params[:model]` – Direct assignment of attributes from hash.
- `accepts_nested_attributes_for` with broad nested params – Nested mass assignment into associated records.
- `update_columns(params_hash)` / `update_column(name, value)` – Bypass validations/callbacks/attr protections.
- `insert_all(params_array)` / `upsert_all(params_array)` – Bulk writes from untrusted hashes.
- Mass assignment of `admin`, `role`, `user_id`, `account_id`, `tenant_id`, `organization_id`, `encrypted_password`, `confirmed_at`, `locked_at`, `provider`, `uid`, or policy flags – Privilege or tenancy bypass.
- Passing `params` hashes into search/filter APIs that trust keys – Dynamic query builders and authorization bypass.

---

## Sink type: Regex, ReDoS and validation

- `Regexp.new(pattern)` – Construct regex from user input.
- `/#{pattern}/` – Interpolated regex literal from data.
- `String#match(regex)` – Match using attacker-supplied regex.
- `String#match?(regex)` – Boolean match using attacker-supplied regex.
- `String#=~ regex` – Regex match with attacker-supplied pattern.
- `scan(regex)` – Scan with attacker-supplied pattern.
- `gsub(regex, replacement)` – Substitution with attacker-supplied regex.
- `sub(regex, replacement)` – Single substitution with attacker-supplied regex.
- `split(regex)` – String split with user-controlled regex.
- `grep(regex)` / `grep_v(regex)` – Enumerable regex matching on attacker-supplied pattern.
- `validates :field, format: { with: /...$/ }` – Validation using `^`/`$` anchors; use `\A`/`\z` for full-string semantics.
- `validates :field, format: { with: /.../ }` – Partial matches rather than full string.
- Custom validators that use `Regexp.new(params[:pattern])` – Validation from user patterns.
- Search filters building regex from user input – e.g. PostgreSQL `where("name ~ ?", pattern)`.
- Mongoid/NoSQL `$regex` queries from params – ReDoS and query abuse.
- `Regexp.new(pattern, timeout: seconds)` / `Regexp.timeout = seconds` on Ruby 3.2+ – ReDoS guards; `nil` means no timeout, so advanced or untrusted patterns still need an explicit limit.

---

## Sink type: Sessions, cookies, CSRF and authorization

- `cookies[:key] = value` – Write arbitrary data into cookies.
- `cookies.permanent[:key] = value` – Long-lived cookie assignment.
- `cookies.signed[:key] = value` – Signed but not necessarily authorized/trusted business value.
- `cookies.encrypted[:key] = value` – Encrypted but still client-stored state.
- Plain `cookies[:remember_token]` – Persistent authentication token in client-controlled storage.
- `session[:user_id] = id` – Session assignment based on input.
- `session[:admin] = params[:admin]` – Privilege state from request data.
- Missing `reset_session` on login/logout/password change – Session fixation risk.
- Controllers with `skip_before_action :verify_authenticity_token` – CSRF disabled surfaces.
- `skip_forgery_protection` – CSRF disabled surfaces.
- `protect_from_forgery with: :null_session` – CSRF config that may be too permissive for cookie-authenticated browser endpoints.
- `config.action_controller.allow_forgery_protection = false` – Global CSRF protection disabled.
- `config.action_controller.forgery_protection_origin_check = false` – Origin check disabled.
- JSON/JS endpoints returning actions that change state without CSRF – State change sinks.
- `skip_before_action :authenticate_user!` – Authentication disabled for controller actions.
- `skip_authorization` / `skip_policy_scope` – Pundit authorization bypass surface.
- `load_and_authorize_resource` skipped or overridden – CanCanCan authorization bypass surface.
- Devise `bypass_sign_in(user)` – Session establishment bypasses normal callbacks/checks.
- `sign_in(User.find(params[:user_id]))` – Establish a session for an identity selected from input without an authorization or credential check.
- `JWT.decode(token, nil, false)` – JWT signature verification disabled.
- `JWT.decode(token, key, true, algorithm: params[:alg])` – Algorithm confusion/attacker-controlled verification settings.
- CORS with credentials plus broad origins – Cross-site authenticated data access.

---

## Sink type: SSL verification, crypto and HTTP client configuration

- `Net::HTTP.start(host, port, use_ssl: true) { |h| h.verify_mode = OpenSSL::SSL::VERIFY_NONE }` – HTTP client with verification disabled.
- `OpenSSL::SSL::VERIFY_NONE` – Explicit SSL verification disable flag.
- `RestClient::Request.execute(verify_ssl: false)` – RestClient with SSL verification disabled.
- `Faraday.new(url, ssl: { verify: false })` – Faraday client without SSL verification.
- `Excon.new(url, ssl_verify_peer: false)` – Excon client without peer verification.
- `OpenURI.open_uri(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)` – OpenURI with disabled verification.
- `HTTParty.get(url, verify: false)` – HTTP client without TLS verification.
- `OpenSSL::SSL::SSLContext#verify_mode = OpenSSL::SSL::VERIFY_NONE` – TLS context verification disabled.
- `Digest::MD5.hexdigest(secret)` / `Digest::SHA1.hexdigest(secret)` – Weak hashing for passwords, tokens, signatures, or cache keys.
- `OpenSSL::Cipher.new("*-ECB")` – ECB mode encryption.
- `OpenSSL::Cipher` CBC/CTR/GCM usage with static IVs, reused nonces, unauthenticated ciphertext, or tainted keys/IVs/salts – Crypto misuse sink.
- `OpenSSL::PKCS5.pbkdf2_hmac(..., iterations)` with low iterations – Weak KDF settings.
- `BCrypt::Password.create(password, cost: low)` – Weak password hashing cost.
- `rand`, `Random`, `srand`, timestamp/PID-derived values – Non-CSPRNG secrets/tokens.
- `SecureRandom` output truncated too aggressively – Weak token entropy.
- Hardcoded or user-controlled `secret_key_base` – Rails signing/encryption compromise.
- Weak `ActiveSupport::MessageVerifier` / `MessageEncryptor` secrets, ciphers, or digest choices – Signed/encrypted payload bypass.
- Session cookie options `secure: false`, `httponly: false`, or `same_site: :none` without Secure – Cookie theft/CSRF surface.

---

## Sink type: XML, XXE and parser configuration

- `Nokogiri::XML(xml)` – XML parsing of tainted input; dangerous with unsafe parse options.
- `Nokogiri::XML::Document.parse(xml, ..., options)` – XML parse with options such as `NOENT`, `DTDLOAD`, `HUGE`, or missing `NONET`.
- Nokogiri config blocks using `cfg.noent`, `cfg.dtdload`, `cfg.huge`, `cfg.nononet`, or custom options without `NONET` – Entity expansion/network-loading risk.
- `Nokogiri::HTML(html)` – HTML parser sink for sanitizer/bypass research.
- `REXML::Document.new(xml)` – XML parser historically exposed to entity expansion/resource attacks.
- `REXML::Parsers::*` – Streaming/tree parsing of tainted XML.
- `LibXML::XML::Document.string(xml)` / `.file(path)` – XML parse with entity/network options.
- `Hash.from_xml(xml)` – ActiveSupport XML-to-hash parsing.
- `ActiveSupport::XmlMini.parse(xml)` – Rails XML parsing backend.
- XML request parameter parsing re-enabled in Rails – Automatic materialization of XML request bodies.
- `Crack::XML.parse(xml)` – XML parser used by some API clients/stacks.
- `Nori.new.parse(xml)` – SOAP/XML parsing.
- `Ox.load(xml)` with unsafe entity/object settings – XML load sink.
- SAML/SOAP parsing with disabled signature, certificate, audience, destination, or clock validation – Auth assertion bypass and XXE-adjacent surface.

---

## Sink type: Mail, SMTP and header injection

- `mail(to:, cc:, bcc:, from:, reply_to:, subject:)` – Header fields with CRLF-controllable values.
- `mail(to: params[:email])` – Arrays or comma-separated addresses can produce multiple recipients; sensitive mail requires exactly one validated recipient.
- `headers[...] = params` – Direct mail header assignment.
- `headers(params_hash)` – Bulk mail header assignment.
- `Mail.new(params[:raw])` – Parse/build raw message from tainted content.
- `Mail::Message#[]=` – Header assignment.
- `Net::SMTP#send_message(message, from, to)` – Tainted raw message or envelope fields.
- `attachments[params[:filename]] = data` – Attachment filename/header injection.
- `add_file(params[:path])` – Attachment from tainted filesystem path.
- Password-reset, magic-login, invitation, or confirmation email URLs generated from `params[:host]`, `request.host`, `X-Forwarded-Host`, or untrusted `default_url_options` – Host header poisoning.

---

## Sink type: Background jobs, queues and async dispatch

- `SomeJob.perform_later(params)` – Raw params passed into a privileged Active Job subclass.
- `params[:job_class].constantize.perform_later(*args)` – Dynamic job class dispatch.
- `SomeJob.set(queue: params[:queue]).perform_later(args)` – Queue/routing controlled by input.
- `SomeWorker.perform_async(params)` – Tainted args stored and later executed by a Sidekiq worker class.
- `Sidekiq::Client.push(class: params[:class], queue: params[:queue], args: params[:args])` – Dynamic Sidekiq class/queue/args.
- `Sidekiq::Client.push_bulk(...)` – Bulk dynamic enqueueing.
- `Resque.enqueue(klass, *args)` – Dynamic queue/class/args.
- `Delayed::Job.enqueue(job)` – Object/YAML-backed job payload materialization.
- `Que.enqueue(job_class, *args)` – Dynamic queue dispatch.
- `Sneakers` / `Shoryuken` message handlers – Queue payloads flowing to deserialization, SQL, file, network, or command sinks.
- Dynamic mailer actions: `Mailer.public_send(params[:action], *args).deliver_later` – Method dispatch and async side effects from data.

---

## Sink type: Cache, key-value stores and poisoning

- `Rails.cache.read(key)` – User-controlled cache key may cross tenants or deserialize attacker-writable values.
- `Rails.cache.write(key, value)` – Cache poisoning and key-space pollution.
- `Rails.cache.fetch(key) { ... }` – Cache poisoning and authorization-boundary bypass.
- `Rails.cache.delete(key)` – User-controlled cache invalidation.
- `Rails.cache.read_multi(*keys)` / `write_multi(hash)` – Bulk key-space access.
- `Rails.cache.increment(key)` / `decrement(key)` – Counter manipulation.
- `Rails.cache.delete_matched(pattern)` – Glob/regex-like cache invalidation from data.
- `cache(params[:key])` in views – Fragment cache poisoning/cross-user content leak.
- HTTP cache helpers `expires_in public: true`, `fresh_when`, `stale?` with tainted params/headers – Shared cache poisoning.
- Cache backends using Marshal/MessagePack/YAML coders with attacker-writable Redis/Memcached/file store – Deserialization sink.
- `Redis#get/set/del/call` with tainted keys/commands – Key-space pollution and command abuse.
- `Redis#eval(script, keys:, argv:)` – Tainted Lua script execution in Redis.
- `Dalli::Client#get/set/delete` / Memcached clients with tainted keys – Key poisoning and cross-tenant reads/writes.

---

## Sink type: Dynamic render paths & routing

- `render params[:template]` – Render dynamic template name from input.
- `render partial: params[:partial]` – Render partial from user input.
- `render file: params[:file]` – Render file using filesystem path from data.
- `render template: params[:template]` – Render template using user input.
- `render layout: params[:layout]` – Dynamic layout selection.
- `render template: "#{params[:controller]}/#{params[:action]}"` – Dynamic controller/action-derived template resolution.
- Legacy route `match ':controller(/:action(/:id(.:format)))'` – Expose arbitrary controller methods as actions.
- `redirect_to controller: params[:c], action: params[:a]` – Dynamic redirects based on controller/action params.
- `prepend_view_path(params[:path])` / `append_view_path(params[:path])` – User-influenced template lookup path.
- `ActionController::Metal.action(params[:action])` or custom dispatch using `params[:action]` – Dynamic action invocation.

---

## Sink type: Rack, headers, proxies and WEBrick parsing

Request accessors below are taint sources or trust-boundary inputs, not terminal sinks; the sink is their later use in redirects, links, cache keys, tenant selection, or security decisions.

- `WEBrick::HTTPRequest#parse` – HTTP parser for raw request; vulnerable to smuggling when misused or deployed behind mismatched proxies.
- `WEBrick::HTTPRequest#body` – Raw request body as parsed; used in downstream sinks.
- `Rack::Request#host` – Host value derived from headers.
- `Rack::Request#ip` – IP address derived from headers/proxy configuration.
- `Rack::Request#scheme` – Scheme derived from headers.
- `Rack::Request#env['HTTP_HOST']` – Raw host header.
- `Rack::Request#env['HTTP_X_FORWARDED_FOR']` – X-Forwarded-For chain.
- `Rack::Request#env['HTTP_X_FORWARDED_PROTO']` – Forwarded protocol value.
- `Rack::Request#env['HTTP_X_FORWARDED_PROTOCOL']` / variant proxy headers – Forwarded scheme confusion.
- `Rack::Request#env['HTTP_X_FORWARDED_HOST']` – Forwarded host header.
- `Rack::Request#env['HTTP_FORWARDED']` – RFC 7239 Forwarded header.
- `request.original_url`, `request.url`, `request.base_url` – Generated from host/protocol headers.
- `ActionDispatch::RemoteIp` trusted proxy misconfiguration – IP spoofing authorization/rate-limit bypass.
- `config.action_dispatch.trusted_proxies` broad or attacker-controlled – Proxy header trust boundary collapse.
- `config.hosts.clear` – Host Authorization disabled.
- Broad `config.host_authorization.exclude` – Host checks bypassed for routes.
- Direct use of request headers in security decisions, redirects, links, logs, cache keys, or tenant resolution – Header injection/poisoning sink.

---

## Sink type: Rails framework APIs and client-side channels

- `ActionController::DataStreaming#send_data` with tainted filename, disposition, content type, or body – Header injection and active-content download.
- `ActionController::Live` streaming of tainted data – Persistent response/XSS and resource exhaustion surface.
- `ActionCable.server.broadcast(params[:stream], payload)` – Cross-tenant stream/data leak and client-side injection.
- `stream_from params[:channel]` / `stream_for object_from_params` – User-controlled subscription target.
- Turbo Stream rendering of tainted `target`, `action`, or HTML – DOM clobbering/XSS/client-side state manipulation.
- `asset_path(params[:asset])`, `asset_url`, `image_url`, `font_url` – Asset URL construction from user data.
- `javascript_include_tag(params[:src])` / `stylesheet_link_tag(params[:href])` – External script/style inclusion.
- `config.active_storage.resolve_model_to_route` and signed blob/proxy routes – Blob access boundary when IDs/tokens leak.
- `ActiveStorage::Blob.find_signed(params[:signed_id])` – Signed blob materialization/access sink.
- `ActiveStorage::Current.url_options` from request host – Host poisoning in generated blob URLs.
- `I18n.backend.store_translations(locale, data)` from user/admin data – Translation poisoning and `_html` XSS.
- `render json: record` / `record.as_json` / `record.serializable_hash` – May expose sensitive attributes unless serialization uses an explicit field allowlist.
- Multi-tenant `Current.account = Account.find(params[:account_id])` patterns – Tenant context from request data.

---

## Sink type: Miscellaneous security-sensitive configuration

- `Rails.application.config.force_ssl = false` – Disable HTTPS enforcement.
- `config.force_ssl = false` in production – Disable HTTPS enforcement.
- `ActionDispatch::Response.default_headers[...]` – Modify default security headers.
- `content_security_policy` with overly permissive directives – CSP misconfiguration sink.
- `csp_meta_tag` with misconfigured CSP – CSP misconfiguration sink.
- `Rails.application.config.action_dispatch.perform_deep_munge = false` – Changes parameter handling behavior.
- `Rails.application.config.action_dispatch.cookies_serializer = :marshal` – Session cookies serialized with Marshal.
- `Rails.application.config.action_dispatch.cookies_serializer = :hybrid` – Hybrid serializer may accept Marshal during migrations.
- `Rails.application.config.filter_parameters` missing sensitive keys – Log leakage sink.
- `Rack::Cors` configuration with `origins '*'` – Overly permissive CORS sink.
- `Rack::Cors` dynamic `origins { true }` – Reflect-all CORS policy.
- `credentials`, `secrets.yml`, `.env`, or initializer values committed/hardcoded – Secret leakage sink.
- `config.consider_all_requests_local = true` in production – Error pages leak internals.
- `config.action_controller.perform_caching` / public caching with user-specific content – Cache-based data leakage.
- `config.active_record.yaml_column_permitted_classes` too broad – YAML object materialization surface.
- `config.active_record.use_yaml_unsafe_load = true` – Unsafe YAML deserialization.
- `config.active_support.use_message_serializer_for_metadata = false` or legacy serializer settings – Signed/encrypted payload compatibility risks.
- Logging request bodies, headers, params, cookies, sessions, tokens, API keys, OAuth codes, Authorization headers, or Set-Cookie values – Logging-based data leak.
- Log injection via unsanitized newlines/control characters in user input – Forged log entries and SIEM bypass.

---

## Detection Rule Library (executable)

The sinks above are backed by an executable rule MegaDB under [`rules/ruby/`](../../rules/ruby/) —
original-wording detection rules, each with a citation and a **green test pair**. A rule is
only counted when its test passes the validation gate (no self-reported greens).

| Engine | Rules | Validation | Index |
|--------|------:|------------|-------|
| Semgrep `.yaml` | 670 | `semgrep --test` → 670/670 green | [`manifest.json`](../../rules/ruby/manifest.json) |
| CodeQL `.ql` | 32 | `codeql test run` → 65/65 tests green | same |

- **Layout & validation commands:** [`rules/ruby/README.md`](../../rules/ruby/README.md)
- **Authoring conventions (toolchain gotchas):** [`rules/ruby/AUTHORING_GUIDE.md`](../../rules/ruby/AUTHORING_GUIDE.md)
- **Taxonomy** (25 categories → CWE → this file's sections): [`rules/ruby/taxonomy.yml`](../../rules/ruby/taxonomy.yml)

### Provenance oracle (real-world fix mining)

Rules are grounded in real fixes, not just synthetic patterns. Distilled corpora under
[`rules/ruby/oracle/`](../../rules/ruby/oracle/):

- `cve-commits.json` — CVE/GHSA → `{repo, vuln_sha, fix_sha, category}` pairs for HIT@vuln / MISS@fix oracle checks.
- `gitlab-fix-corpus.json` — 1,166 high-signal `gitlab-org/gitlab` security-fix commits (3-year window) from canonical signals (`Changelog: security`, `security-*` branch merges, CVE/CWE refs).
- `security-fix-corpus.json` — 1,018 of those fixes after Ruby-diff analysis: root cause, fix summary, tainted input → sink, and a concrete rule idea per commit. Dominant classes: auth-session/IDOR (CWE-639/287), XSS, ReDoS, path-traversal, SSRF.
- `message-triage-summary.json` — title+message triage over 189,153 commits → 18,202 security-relevant and 14,725 needing diff analysis — the backlog feed for new Tier-A rules.
