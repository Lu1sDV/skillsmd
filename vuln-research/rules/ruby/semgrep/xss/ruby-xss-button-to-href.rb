# Fixture covering button_to with attacker-controlled action URL.

def submit_to
  # ruleid: ruby-xss-button-to-href
  button_to("Go", params[:action_url])
end

def submit_fetch
  # ruleid: ruby-xss-button-to-href
  button_to("Go", params.fetch(:dest))
end

def submit_route
  # ok: ruby-xss-button-to-href
  button_to("Delete", post_path(@post), method: :delete)
end
