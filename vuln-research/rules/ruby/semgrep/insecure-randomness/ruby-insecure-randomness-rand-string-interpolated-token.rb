# Fixture for interpolated rand identifiers.

def invite_link
  # ruleid: ruby-insecure-randomness-rand-string-interpolated-token
  invite_token = "inv-#{rand(99999)}"
  invite_token
end

def invite_link_secure
  # ok: ruby-insecure-randomness-rand-string-interpolated-token
  invite_token = "inv-#{SecureRandom.hex(16)}"
  invite_token
end

def cache_bucket
  # ok: ruby-insecure-randomness-rand-string-interpolated-token
  bucket_label = "shard-#{rand(8)}"
  bucket_label
end
