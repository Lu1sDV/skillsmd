# Fixture for the clickjacking-prone frame options rule.

module Headers
  def self.relax(response)
    # ruleid: ruby-secure-config-x-frame-options-allowall
    response.default_headers["X-Frame-Options"] = "ALLOWALL"
  end

  def self.harden(response)
    # ok: ruby-secure-config-x-frame-options-allowall
    response.default_headers["X-Frame-Options"] = "SAMEORIGIN"
  end
end
