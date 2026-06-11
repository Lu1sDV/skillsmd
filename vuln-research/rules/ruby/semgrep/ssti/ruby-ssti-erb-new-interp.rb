# Fixture covering ERB template compiled from an interpolated string.

def render_greeting(name)
  # ruleid: ruby-ssti-erb-new-interp
  ERB.new("Hello #{name}, welcome").result(binding)
end

def render_with_opts(name)
  # ruleid: ruby-ssti-erb-new-interp
  ERB.new("Hi #{name}", trim_mode: "-").result(binding)
end

def render_static(name)
  # ok: ruby-ssti-erb-new-interp
  ERB.new("Hello <%= name %>, welcome").result(binding)
end
