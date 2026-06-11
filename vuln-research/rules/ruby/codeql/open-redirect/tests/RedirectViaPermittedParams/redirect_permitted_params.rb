class CallbacksController < ActionController::Base
  # True positive: taint is preserved through `permit`, so the redirect target
  # resolved from the strong-parameters hash is still attacker-controlled.
  def follow
    safe = params.permit(:next_url)
    redirect_to safe[:next_url]
  end

  # Safe: redirect to a constant path; the permitted params are never used as
  # the redirect target.
  def follow_safe
    params.permit(:next_url)
    redirect_to "/home"
  end
end
