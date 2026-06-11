# Fixture for the legacy TLS version rule.

def legacy_context
  ctx = OpenSSL::SSL::SSLContext.new
  # ruleid: ruby-crypto-tls-min-tls-version-legacy
  ctx.ssl_version = :TLSv1
  ctx
end

def modern_context
  ctx = OpenSSL::SSL::SSLContext.new
  # ok: ruby-crypto-tls-min-tls-version-legacy
  ctx.min_version = OpenSSL::SSL::TLS1_2_VERSION
  ctx
end
