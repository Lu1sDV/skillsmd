# Backdoor pattern: a hard-coded hex blob is decoded and evaluated at runtime.
def load_hidden_logic
  # true positive: hex constant decoded via pack, then evaluated
  blob = "6465616462656566"
  payload = [blob].pack("H*")
  eval(payload)
end

def safe_eval
  # negative: a fixed, reviewable expression, not a decoded constant
  eval("1 + 1")
end
