# Fixture for Markaby markup source created from interpolation.

def build_page(snippet)
  # ruleid: ruby-ssti-markaby-eval
  Markaby::Builder.new.instance_eval("h1 #{snippet}")
end

def build_page_safe
  # ok: ruby-ssti-markaby-eval
  Markaby::Builder.new.instance_eval("h1 'Static title'")
end
