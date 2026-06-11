# Fixture for the Net::SMTP verification disable rule.

def mailer
  smtp = Net::SMTP.new("mail.example.com", 587)
  # ruleid: ruby-crypto-tls-smtp-openssl-verify-none
  smtp.openssl_verify_mode = OpenSSL::SSL::VERIFY_NONE
  smtp
end

def mailer_secure
  smtp = Net::SMTP.new("mail.example.com", 587)
  # ok: ruby-crypto-tls-smtp-openssl-verify-none
  smtp.openssl_verify_mode = OpenSSL::SSL::VERIFY_PEER
  smtp
end
