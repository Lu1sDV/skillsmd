# Fixture for referer-driven redirects.

class BounceController < ApplicationController
  def back
    # ruleid: ruby-open-redirect-redirect-to-referer
    redirect_to request.referer
  end

  def back_spelled
    # ruleid: ruby-open-redirect-redirect-to-referer
    redirect_to(request.referrer)
  end

  def safe_back
    # ok: ruby-open-redirect-redirect-to-referer
    redirect_back_or_to root_path
  end
end
