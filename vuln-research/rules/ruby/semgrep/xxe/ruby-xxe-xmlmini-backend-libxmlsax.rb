# Fixture for the XmlMini SAX-backend configuration rule.

def configure_sax
  # ruleid: ruby-xxe-xmlmini-backend-libxmlsax
  ActiveSupport::XmlMini.backend = "LibXMLSAX"
end

def configure_default
  # ok: ruby-xxe-xmlmini-backend-libxmlsax
  ActiveSupport::XmlMini.backend = "REXML"
end
