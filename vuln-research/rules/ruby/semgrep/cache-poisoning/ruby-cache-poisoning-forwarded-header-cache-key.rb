# Fixture for cache keys folding in untrusted forwarding headers.
# Flagged calls read attacker headers into the key; safe call uses a fixed segment.

class AssetsController < ApplicationController
  def manifest
    # ruleid: ruby-cache-poisoning-forwarded-header-cache-key
    Rails.cache.fetch("manifest/#{request.headers['X-Forwarded-Host']}") { build_manifest }

    # ruleid: ruby-cache-poisoning-forwarded-header-cache-key
    Rails.cache.write("manifest/#{request.headers['X-Original-URL']}", build_manifest)
  end

  def safe_manifest
    # ok: ruby-cache-poisoning-forwarded-header-cache-key
    Rails.cache.fetch("manifest/v3") { build_manifest }
  end
end
