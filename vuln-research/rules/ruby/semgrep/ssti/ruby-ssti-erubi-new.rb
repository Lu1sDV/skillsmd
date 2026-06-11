# Fixture for Erubi engine built from interpolated template source.

def compile_template(snippet)
  # ruleid: ruby-ssti-erubi-new
  src = Erubi::Eruby.new("Body: #{snippet}").src
  eval(src)
end

def compile_static
  # ok: ruby-ssti-erubi-new
  Erubi::Eruby.new("Body: <%= snippet %>").src
end
