# Fixture for memoizing under an attacker-influenced fetch key.
# Flagged fetches take the key from request data; safe fetch scopes by user.

class DashboardController < ApplicationController
  def widget
    # ruleid: ruby-cache-poisoning-rails-cache-fetch-tainted-key
    Rails.cache.fetch(params[:widget_key]) { build_widget }

    # ruleid: ruby-cache-poisoning-rails-cache-fetch-tainted-key
    Rails.cache.fetch("widget/#{params[:name]}") { build_widget }
  end

  def safe_widget
    # ok: ruby-cache-poisoning-rails-cache-fetch-tainted-key
    Rails.cache.fetch("widget/#{current_user.id}") { build_widget }
  end
end
