# Fixture for the define_method rule.
# Method names from request data are flagged; a literal symbol is safe.

class Widget
  def self.register(params)
    # ruleid: ruby-code-injection-define-method
    define_method(params[:name]) { nil }
  end
end

def per_object(obj, params)
  # ruleid: ruby-code-injection-define-method
  obj.define_singleton_method(params[:m]) { nil }
end

class Gadget
  # ok: ruby-code-injection-define-method
  define_method(:render) { "<div>" }
end
