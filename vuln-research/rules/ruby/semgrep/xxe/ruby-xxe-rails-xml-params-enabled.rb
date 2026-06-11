# Fixture for the Rails XML param-parser re-enable rule.

def register_xml_parser
  # ruleid: ruby-xxe-rails-xml-params-enabled
  ActionDispatch::Request.parameter_parsers[Mime[:xml]] = lambda { |raw| Hash.from_xml(raw) }
end

def register_json_only
  # ok: ruby-xxe-rails-xml-params-enabled
  ActionDispatch::Request.parameter_parsers[Mime[:json]] = lambda { |raw| JSON.parse(raw) }
end
