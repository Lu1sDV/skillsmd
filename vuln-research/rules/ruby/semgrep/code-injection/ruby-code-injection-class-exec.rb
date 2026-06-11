# Fixture for the class_exec / module_exec rule.
# Request-derived args forwarded into the block are flagged; a symbol is safe.

def build(klass, params)
  # ruleid: ruby-code-injection-class-exec
  klass.class_exec(params[:meth]) { |m| define_method(m) {} }
end

def build_mod(mod, params)
  # ruleid: ruby-code-injection-class-exec
  mod.module_exec(params[:const]) { |c| const_set(c, 1) }
end

def safe_build(klass)
  # ok: ruby-code-injection-class-exec
  klass.class_exec(:ping) { |m| define_method(m) {} }
end
