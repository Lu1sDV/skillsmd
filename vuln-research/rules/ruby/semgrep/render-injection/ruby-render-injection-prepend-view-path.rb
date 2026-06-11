# Fixture for prepend_view_path fed by request input.

class TenantController < ApplicationController
  def configure
    # ruleid: ruby-render-injection-prepend-view-path
    prepend_view_path(params[:theme_dir])
  end

  def safe_configure
    # ok: ruby-render-injection-prepend-view-path
    prepend_view_path(Rails.root.join("app", "themes", "default"))
  end
end
