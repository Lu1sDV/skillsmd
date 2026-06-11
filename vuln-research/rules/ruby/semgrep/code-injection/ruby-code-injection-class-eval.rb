# Fixture for the class_eval / module_eval rule.
# Interpolated definition strings are flagged; the static string is safe.

def add_method(klass, params)
  # ruleid: ruby-code-injection-class-eval
  klass.class_eval("def #{params[:name]}; end")
end

def extend_module(mod, params)
  # ruleid: ruby-code-injection-class-eval
  mod.module_eval("CONST = #{params[:val]}")
end

def safe_add(klass)
  # ok: ruby-code-injection-class-eval
  klass.class_eval("def ready?; true; end")
end
