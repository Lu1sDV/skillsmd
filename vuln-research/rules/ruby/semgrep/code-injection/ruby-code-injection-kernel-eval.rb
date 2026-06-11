# Fixture for the Kernel eval rule.
# Flagged lines below execute attacker-influenced Ruby; the safe line does not.

def run_formula(params)
  # ruleid: ruby-code-injection-kernel-eval
  eval("result = #{params[:formula]}")
end

def run_global(params)
  # ruleid: ruby-code-injection-kernel-eval
  Kernel.eval("puts #{params[:expr]}")
end

def safe_eval
  # ok: ruby-code-injection-kernel-eval
  eval("1 + 1")
end
