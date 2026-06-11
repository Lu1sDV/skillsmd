# Fixture for the SAML signing/expiration check rule.

def relax(settings)
  # ruleid: ruby-xxe-saml-clock-drift
  settings.security[:want_messages_signed] = false
  settings
end

def strict(settings)
  # ok: ruby-xxe-saml-clock-drift
  settings.security[:want_messages_signed] = true
  settings
end
