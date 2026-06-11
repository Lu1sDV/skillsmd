# Obfuscated-loader pattern: a hard-coded hex blob decodes into an import path.
def load_hidden_module
  # true positive: hex constant decoded via pack, then used as a require path
  blob = "6c69622f7061796c6f6164"
  path = [blob].pack("H*")
  require(path)
end

def safe_require
  # negative: a fixed, reviewable library name
  require("json")
end
