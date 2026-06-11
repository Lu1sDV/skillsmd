# Fixture for cache keys derived from the inbound Host header.
# Flagged calls fold request.host into the key; safe call uses a configured host.

class PagesController < ApplicationController
  def home
    # ruleid: ruby-cache-poisoning-host-header-cache-key
    Rails.cache.fetch("home/#{request.host}") { render_home }

    # ruleid: ruby-cache-poisoning-host-header-cache-key
    Rails.cache.write("home/#{request.env["HTTP_HOST"]}", render_home)
  end

  def safe_home
    # ok: ruby-cache-poisoning-host-header-cache-key
    Rails.cache.fetch("home/#{Rails.application.config.canonical_host}") { render_home }
  end
end
