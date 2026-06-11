# Fixture for the Net::SMTP.start host check.

def relay_mail(host)
  # ruleid: ruby-ssrf-net-smtp-start
  Net::SMTP.start("#{host}", 25)
end

def relay_mail_fixed
  # ok: ruby-ssrf-net-smtp-start
  Net::SMTP.start("smtp.example.com", 25)
end
