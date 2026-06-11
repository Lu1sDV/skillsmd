# Fixture for the autoload rule.
# Autoload paths from external input are flagged; a fixed path is safe.

def register(params)
  # ruleid: ruby-code-injection-autoload-path
  autoload(:Plugin, params[:path])
end

def register_interp(name)
  # ruleid: ruby-code-injection-autoload-path
  autoload(:Driver, "drivers/#{name}.rb")
end

def safe_register
  # ok: ruby-code-injection-autoload-path
  autoload(:Helper, "lib/helper.rb")
end
