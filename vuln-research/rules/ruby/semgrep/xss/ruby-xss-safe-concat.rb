# Fixture covering safe_concat output-buffer appending.

def emit(name)
  # ruleid: ruby-xss-safe-concat
  safe_concat("<li>#{name}</li>")
end

def emit_param
  # ruleid: ruby-xss-safe-concat
  safe_concat(params[:row])
end

def emit_static
  # ok: ruby-xss-safe-concat
  safe_concat("<hr>")
end
