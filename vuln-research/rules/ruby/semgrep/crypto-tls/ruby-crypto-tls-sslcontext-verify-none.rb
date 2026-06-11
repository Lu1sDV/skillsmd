# Fixture for the TLS hostname verification disable rule.

def build_context
  ctx = OpenSSL::SSL::SSLContext.new
  ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
  # ruleid: ruby-crypto-tls-sslcontext-verify-none
  ctx.verify_hostname = false
  ctx
end

def build_context_secure
  ctx = OpenSSL::SSL::SSLContext.new
  ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
  # ok: ruby-crypto-tls-sslcontext-verify-none
  ctx.verify_hostname = true
  ctx
end
