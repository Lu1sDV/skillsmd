# Fixture for publicly cacheable responses that depend on request input.
# Flagged action marks a param-dependent response public; safe action keeps it private.

class FeedController < ApplicationController
  def personalized
    locale = params[:locale]
    @items = Feed.for(locale)
    # ruleid: ruby-cache-poisoning-http-expires-public-tainted
    expires_in(5.minutes, public: true)
  end

  def shared
    @items = Feed.global
    # ok: ruby-cache-poisoning-http-expires-public-tainted
    expires_in(5.minutes, public: false)
  end
end
