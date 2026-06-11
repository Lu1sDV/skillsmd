module Codegen
  # true positive: the public `attr` parameter is interpolated into a code
  # string that is later evaluated. A caller passing untrusted input gets RCE.
  def self.define_reader(attr)
    code = "def #{attr}; @#{attr}; end"
    eval(code)
  end

  # negative: fixed code string, no parameter reaches eval
  def self.define_noop
    eval("def noop; end")
  end
end
