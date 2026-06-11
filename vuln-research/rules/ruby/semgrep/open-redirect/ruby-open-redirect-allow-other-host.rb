# Fixture for the allow_other_host opt-in escape hatch.

class CallbackController < ApplicationController
  def finish
    # ruleid: ruby-open-redirect-allow-other-host
    redirect_to(params[:url], allow_other_host: true)
  end

  def finish_var
    target = build_target
    # ruleid: ruby-open-redirect-allow-other-host
    redirect_to(target, allow_other_host: true)
  end

  def safe_fixed_external
    # ok: ruby-open-redirect-allow-other-host
    redirect_to("/static/path", allow_other_host: true)
  end

  def safe_default
    # ok: ruby-open-redirect-allow-other-host
    redirect_to(params[:url])
  end
end
