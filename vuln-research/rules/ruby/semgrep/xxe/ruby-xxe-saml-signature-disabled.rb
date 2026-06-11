# Fixture for the SAML signature-validation rule.

def build_settings(settings)
  # ruleid: ruby-xxe-saml-signature-disabled
  settings.want_assertions_signed = false
  settings
end

def hardened(settings)
  # ok: ruby-xxe-saml-signature-disabled
  settings.want_assertions_signed = true
  settings
end
