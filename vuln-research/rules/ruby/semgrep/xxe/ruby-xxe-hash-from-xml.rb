# Fixture for the Hash.from_xml rule.

def import_settings
  # ruleid: ruby-xxe-hash-from-xml
  Hash.from_xml(request.raw_post)
end

def import_param
  # ruleid: ruby-xxe-hash-from-xml
  Hash.from_xml(params[:payload])
end

def import_fixed
  # ok: ruby-xxe-hash-from-xml
  Hash.from_xml("<config><k>v</k></config>")
end
