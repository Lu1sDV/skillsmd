# Fixture for fetching a raw request parameter as a URL.

def proxy
  # ruleid: ruby-ssrf-net-http-get-params
  body = Net::HTTP.get(URI(params[:url]))
  render plain: body
end

def proxy_fixed
  allowed = "https://api.example.com/data"
  # ok: ruby-ssrf-net-http-get-params
  body = Net::HTTP.get(URI(allowed))
  render plain: body
end
