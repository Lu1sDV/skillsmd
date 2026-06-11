# Fixture for url_for host poisoning.

class LinkController < ApplicationController
  def share
    # ruleid: ruby-open-redirect-url-for-host
    link = url_for(host: params[:host], controller: "posts", action: "show")
    render plain: link
  end

  def share_trailing
    # ruleid: ruby-open-redirect-url-for-host
    link = url_for(controller: "posts", host: params[:host])
    render plain: link
  end

  def safe_share
    # ok: ruby-open-redirect-url-for-host
    link = url_for(controller: "posts", action: "show", id: params[:id])
    render plain: link
  end
end
