# Fixture for a layout name interpolated from request input.

class StorefrontController < ApplicationController
  def show
    # ruleid: ruby-render-injection-layout-interpolated
    render "storefront/show", layout: "themes/#{params[:theme]}"
  end

  def safe_show
    # ok: ruby-render-injection-layout-interpolated
    render "storefront/show", layout: "themes/default"
  end
end
