# Fixture for RM003: JSON parse without parse_limits (OOM/DoS)

# BAD: JSON.parse on HTTP response body, no parse_limits keyword
def parse_response_bad(response)
  JSON.parse(response.body) # BAD: no parse_limits
end

# BAD: Gitlab::Json.parse without parse_limits
def parse_gitlab_bad(body)
  Gitlab::Json.parse(body) # BAD: no parse_limits
end

# BAD: Gitlab::Json.safe_parse without parse_limits
def safe_parse_bad(body)
  Gitlab::Json.safe_parse(body) # BAD: no parse_limits
end

# GOOD: JSON.parse with parse_limits keyword
def parse_response_good(response)
  JSON.parse(response.body, parse_limits: { max_depth: 10, max_array_size: 100, max_json_size_bytes: 1_048_576 }) # GOOD: parse_limits present
end

# GOOD: Gitlab::Json.parse with parse_limits keyword
def parse_gitlab_good(body)
  Gitlab::Json.parse(body, parse_limits: { max_depth: 10, max_array_size: 100, max_json_size_bytes: 1_048_576 }) # GOOD: parse_limits present
end

# GOOD: Gitlab::Json.safe_parse with parse_limits keyword
def safe_parse_good(body)
  Gitlab::Json.safe_parse(body, parse_limits: { max_depth: 10, max_array_size: 100, max_json_size_bytes: 1_048_576 }) # GOOD: parse_limits present
end
