# Fixture for the XmlMini.parse rule.

def decode_body
  # ruleid: ruby-xxe-xmlmini-parse
  ActiveSupport::XmlMini.parse(request.raw_post)
end

def decode_param
  # ruleid: ruby-xxe-xmlmini-parse
  ActiveSupport::XmlMini.parse(params[:doc])
end

def decode_const
  # ok: ruby-xxe-xmlmini-parse
  ActiveSupport::XmlMini.parse("<x/>")
end
