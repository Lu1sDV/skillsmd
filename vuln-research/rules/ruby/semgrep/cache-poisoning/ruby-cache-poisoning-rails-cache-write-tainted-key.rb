# Fixture for writing cache entries under an attacker-influenced key.
# Flagged writes take the key from request data; safe write uses a server id.

class ReportController < ApplicationController
  def store
    # ruleid: ruby-cache-poisoning-rails-cache-write-tainted-key
    Rails.cache.write(params[:slug], rendered_html)

    # ruleid: ruby-cache-poisoning-rails-cache-write-tainted-key
    Rails.cache.write("report/#{params[:slug]}", rendered_html)
  end

  def safe_store
    # ok: ruby-cache-poisoning-rails-cache-write-tainted-key
    Rails.cache.write("report/#{current_user.id}", rendered_html)
  end
end
