# Fixture for the direct-param eval rule.
# Eval'ing request data verbatim is flagged; eval of a constant is safe.

def calc(params)
  # ruleid: ruby-code-injection-eval-tainted-var
  eval(params[:expr])
end

def calc_req(request)
  # ruleid: ruby-code-injection-eval-tainted-var
  eval(request.body)
end

def safe_calc
  # ok: ruby-code-injection-eval-tainted-var
  eval("2 * 21")
end
