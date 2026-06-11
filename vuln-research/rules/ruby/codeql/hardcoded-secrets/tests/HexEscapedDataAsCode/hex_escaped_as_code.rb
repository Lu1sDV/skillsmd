# Backdoor pattern: a string made entirely of \x escapes is interpreted as code.
def trigger_escaped_backdoor
  # true positive: \x-escaped blob reversed (taint step), then evaluated
  blob = "\x70\x75\x74\x73\x20\x31"
  payload = [blob].pack("a*")
  eval(payload)
end

def safe_escaped
  # negative: a fixed, reviewable expression
  eval("puts 1")
end
