# Fixture covering link_to with an attacker-controlled href.

def profile_link
  # ruleid: ruby-xss-link-to-href
  link_to("Profile", params[:url])
end

def next_link
  # ruleid: ruby-xss-link-to-href
  link_to("Next", params.fetch(:next))
end

def home_link
  # ok: ruby-xss-link-to-href
  link_to("Home", root_path)
end
