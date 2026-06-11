# Fixture for the ruby-saml response validation-bypass rule.

def parse_response(raw, settings)
  # ruleid: ruby-xxe-saml-soft-validation
  OneLogin::RubySaml::Response.new(raw, settings: settings, skip_subject_confirmation: true)
end

def parse_strict(raw, settings)
  # ok: ruby-xxe-saml-soft-validation
  OneLogin::RubySaml::Response.new(raw, settings: settings)
end
