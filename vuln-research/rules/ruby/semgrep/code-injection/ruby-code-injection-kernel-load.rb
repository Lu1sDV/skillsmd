# Fixture for the Kernel#load rule.
# Loading a request-derived path is flagged; a fixed file path is safe.

def plugin(params)
  # ruleid: ruby-code-injection-kernel-load
  load(params[:plugin_path])
end

def plugin_interp(name)
  # ruleid: ruby-code-injection-kernel-load
  load("plugins/#{name}.rb")
end

def safe_plugin
  # ok: ruby-code-injection-kernel-load
  load("config/boot.rb")
end
