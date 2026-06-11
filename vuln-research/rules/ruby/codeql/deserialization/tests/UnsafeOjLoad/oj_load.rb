require "oj"

class PayloadsController < ApplicationController
  def ingest
    body = params[:payload]
    # Oj.load defaults to :object mode -> arbitrary object instantiation / RCE.
    obj = Oj.load(body)
    render plain: obj.inspect
  end

  def safe_ingest
    body = params[:payload]
    # Explicit safe mode disables object instantiation.
    obj = Oj.load(body, mode: :strict)
    render plain: obj.inspect
  end
end
