# Fixture for String#scan with a client-supplied pattern.
# The flagged line scans with a params-built regex; the safe line uses a literal.

def extract(doc, params)
  # ruleid: ruby-redos-scan-dynamic
  doc.scan(Regexp.new(params[:token]))
end

def extract_fixed(doc)
  # ok: ruby-redos-scan-dynamic
  doc.scan(/\d{4}/)
end
