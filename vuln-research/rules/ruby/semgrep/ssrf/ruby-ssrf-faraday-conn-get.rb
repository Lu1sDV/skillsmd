# Fixture for a Faraday connection GET with interpolated target.

def call_api(conn, host)
  # ruleid: ruby-ssrf-faraday-conn-get
  conn.get("https://#{host}/resource")
end

def call_api_fixed(conn)
  # ok: ruby-ssrf-faraday-conn-get
  conn.get("/resource")
end
