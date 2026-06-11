# Fixture for the threaded eval rule.
# Interpolated eval inside a thread is flagged; a static thread body is safe.

def background(params)
  # ruleid: ruby-code-injection-thread-eval
  Thread.new { eval("compute #{params[:job]}") }
end

def background_start(name)
  # ruleid: ruby-code-injection-thread-eval
  Thread.start { eval("run_#{name}") }
end

def safe_background
  # ok: ruby-code-injection-thread-eval
  Thread.new { eval("flush_cache") }
end
