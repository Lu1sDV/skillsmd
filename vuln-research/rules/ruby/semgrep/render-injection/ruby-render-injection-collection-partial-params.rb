# Fixture for a collection render with a request-controlled partial name.

class FeedController < ApplicationController
  def index
    # ruleid: ruby-render-injection-collection-partial-params
    render partial: params[:row], collection: @items
  end

  def safe_index
    # ok: ruby-render-injection-collection-partial-params
    render partial: "feed/row", collection: @items
  end
end
