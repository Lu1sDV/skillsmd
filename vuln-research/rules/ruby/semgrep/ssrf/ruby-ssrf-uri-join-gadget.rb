# Fixture for the URI.join host-override gadget.

def build_url(params)
  base = "https://api.example.com/"
  # ruleid: ruby-ssrf-uri-join-gadget
  URI.join(base, params[:next])
end

def build_url_interp(user_path)
  base = "https://api.example.com/"
  # ruleid: ruby-ssrf-uri-join-gadget
  URI.join(base, "v1/#{user_path}")
end

def build_url_fixed
  base = "https://api.example.com/"
  # ok: ruby-ssrf-uri-join-gadget
  URI.join(base, "v1/health")
end
