# Fixture for interpolated link/button hrefs with an unconstrained scheme.

module NavHelper
  def external_link(profile)
    # ruleid: ruby-open-redirect-link-to-javascript-scheme
    link_to("Site", "#{profile.website}")
  end

  def cta(record)
    # ruleid: ruby-open-redirect-link-to-javascript-scheme
    button_to("Open", "https://#{record.host}/open")
  end

  def safe_relative(record)
    # ok: ruby-open-redirect-link-to-javascript-scheme
    link_to("Open", "/records/#{record.id}")
  end
end
