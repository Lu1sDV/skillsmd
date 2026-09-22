# frozen_string_literal: true

# BAD: JSON.parse on request.body.read with no max_nesting — unbounded depth DoS
class WebhookController < ApplicationController
  def receive
    body = request.body.read
    data = JSON.parse(body) # BAD: no max_nesting limit
    process(data)
  end
end

# BAD: JSON.parse directly on request.body.read inline
class ApiController < ApplicationController
  def ingest
    payload = JSON.parse(request.body.read) # BAD: no max_nesting limit
    render json: { ok: true }
  end
end

# BAD: JSON.parse on request.raw_post with no max_nesting
class HooksController < ApplicationController
  def create
    data = JSON.parse(request.raw_post) # BAD: no max_nesting limit
    handle(data)
  end
end

# GOOD: JSON.parse with max_nesting argument — depth is bounded
class SafeWebhookController < ApplicationController
  def receive
    body = request.body.read
    data = JSON.parse(body, max_nesting: 100) # GOOD: depth cap present
    process(data)
  end
end

# GOOD: JSON.parse on a non-request string — not flagged (not request body)
class UtilController < ApplicationController
  def load_config
    config_str = File.read('config.json')
    cfg = JSON.parse(config_str) # GOOD: not a request body read
    render json: cfg
  end
end

# GOOD: JSON.parse on a literal string — not flagged
class LiteralController < ApplicationController
  def demo
    result = JSON.parse('{"a":1}') # GOOD: literal, not request body
    render json: result
  end
end
