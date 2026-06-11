# Fixture: keying the cache on a request header versus on the current user id.

class PageCache
  def render_for(request)
    # ruleid: ruby-http-parsing-header-in-cache-key
    Rails.cache.fetch("page/#{request.headers['X-Variant']}") { build_page }
  end

  def render_scoped
    # ok: ruby-http-parsing-header-in-cache-key
    Rails.cache.fetch("page/#{current_user.id}") { build_page }
  end
end
