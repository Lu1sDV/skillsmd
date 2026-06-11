# Fixture for mutating view_paths with request input.

class SkinController < ApplicationController
  def apply
    # ruleid: ruby-render-injection-view-paths-unshift
    view_paths.unshift(params[:skin_dir])
  end

  def safe_apply
    # ok: ruby-render-injection-view-paths-unshift
    view_paths.unshift(Rails.root.join("app", "skins", "default"))
  end
end
