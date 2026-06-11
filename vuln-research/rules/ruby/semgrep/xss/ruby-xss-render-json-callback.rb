# Fixture covering JSONP callback injection via render json.

def feed
  # ruleid: ruby-xss-render-json-callback
  render json: @items, callback: params[:callback]
end

def feed_plain
  # ok: ruby-xss-render-json-callback
  render json: @items
end
