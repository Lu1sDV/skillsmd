# Fixture for the Curl::Easy.new destination check.

def grab(host)
  # ruleid: ruby-ssrf-curb-easy-new
  easy = Curl::Easy.new("https://#{host}/blob")
  easy.perform
end

def grab_fixed
  # ok: ruby-ssrf-curb-easy-new
  easy = Curl::Easy.new("https://blob.example.com/blob")
  easy.perform
end
