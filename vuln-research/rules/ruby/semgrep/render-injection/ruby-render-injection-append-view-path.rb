# Fixture for append_view_path fed by request input.

class BrandController < ApplicationController
  def setup
    # ruleid: ruby-render-injection-append-view-path
    append_view_path params[:brand_views]
  end

  def safe_setup
    # ok: ruby-render-injection-append-view-path
    append_view_path "app/views/brands"
  end
end
