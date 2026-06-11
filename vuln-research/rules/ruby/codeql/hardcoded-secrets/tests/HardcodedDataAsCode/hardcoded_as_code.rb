# Backdoor pattern: a hard-coded hex blob is decoded and interpreted as code.
def trigger_backdoor
  # true positive: hex constant decoded via pack, then evaluated
  blob = "deadbeef1337cafe"
  payload = [blob].pack("H*")
  instance_eval(payload)
end

def safe_path
  # negative: a fixed, reviewable expression
  instance_eval("self")
end
