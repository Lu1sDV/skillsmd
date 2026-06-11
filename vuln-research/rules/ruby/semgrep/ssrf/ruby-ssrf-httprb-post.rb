# Fixture for the http.rb HTTP.post destination check.

def send_event(host, body)
  # ruleid: ruby-ssrf-httprb-post
  HTTP.post("https://#{host}/events", body: body)
end

def send_event_fixed(body)
  # ok: ruby-ssrf-httprb-post
  HTTP.post("https://events.example.com/events", body: body)
end
