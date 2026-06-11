# Fixture for ERB compiled from interpolation then evaluated with a locals hash.

def render_invoice(label)
  # ruleid: ruby-ssti-erb-result-with-hash
  ERB.new("Total for #{label}: <%= amount %>").result_with_hash(amount: 10)
end

def render_invoice_safe
  # ok: ruby-ssti-erb-result-with-hash
  ERB.new("Total for <%= label %>: <%= amount %>").result_with_hash(label: "x", amount: 10)
end
