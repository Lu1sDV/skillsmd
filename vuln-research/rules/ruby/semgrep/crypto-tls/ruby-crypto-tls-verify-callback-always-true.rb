# Fixture for the always-true verify_callback rule.

def context
  ctx = OpenSSL::SSL::SSLContext.new
  ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
  # ruleid: ruby-crypto-tls-verify-callback-always-true
  ctx.verify_callback = lambda { |preverify_ok, store_context| true }
  ctx
end

def context_secure
  ctx = OpenSSL::SSL::SSLContext.new
  ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
  # ok: ruby-crypto-tls-verify-callback-always-true
  ctx.verify_callback = lambda { |preverify_ok, store_context| preverify_ok }
  ctx
end
