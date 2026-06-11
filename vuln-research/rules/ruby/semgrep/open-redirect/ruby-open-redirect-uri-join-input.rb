# Fixture for URI.join base override via user input.

class ProxyController < ApplicationController
  def follow
    # ruleid: ruby-open-redirect-uri-join-input
    target = URI.join("https://app.example.com/", params[:path])
    redirect_to target.to_s
  end

  def follow_interp(user)
    # ruleid: ruby-open-redirect-uri-join-input
    target = URI.join("https://app.example.com/", "#{user.next_path}")
    redirect_to target.to_s
  end

  def follow_safe
    # ok: ruby-open-redirect-uri-join-input
    target = URI.join("https://app.example.com/", "settings")
    redirect_to target.to_s
  end
end
