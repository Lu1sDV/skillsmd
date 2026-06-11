# Fixture for tainted asset URL construction.

module ProfileHelper
  def avatar(params)
    # ruleid: ruby-rails-misc-asset-path-tainted
    asset_path(params[:avatar])
  end

  def banner(params)
    # ruleid: ruby-rails-misc-asset-path-tainted
    image_url(params[:banner])
  end

  def avatar_safe
    # ok: ruby-rails-misc-asset-path-tainted
    asset_path("avatars/default.png")
  end
end
