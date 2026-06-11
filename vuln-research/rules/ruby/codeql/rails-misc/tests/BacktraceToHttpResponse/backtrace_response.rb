class OrdersController < ApplicationController

  # Unsafe: the rescued exception's backtrace is rendered to the client.
  def checkout
    process_payment()
  rescue => e
    render body: e.backtrace, content_type: "text/plain"
  end

  # Safe: only a static, non-sensitive message reaches the client.
  def checkout_safe
    process_payment()
  rescue => e
    Rails.logger.error(e.backtrace)
    render body: "Checkout failed, please retry", content_type: "text/plain"
  end

end
