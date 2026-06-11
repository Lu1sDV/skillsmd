# Fixture for redirect_back_or_to with a tainted primary target.

class CheckoutController < ApplicationController
  def complete
    # ruleid: ruby-open-redirect-redirect-back-or-to-params
    redirect_back_or_to(params[:return_to])
  end

  def complete_opt
    # ruleid: ruby-open-redirect-redirect-back-or-to-params
    redirect_back_or_to(params[:url], allow_other_host: true)
  end

  def complete_safe
    # ok: ruby-open-redirect-redirect-back-or-to-params
    redirect_back_or_to(orders_path)
  end
end
