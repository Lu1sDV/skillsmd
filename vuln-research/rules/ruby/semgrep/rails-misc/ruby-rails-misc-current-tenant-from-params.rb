# Fixture for tenant context set from request param.

class ApplicationController < ActionController::Base
  def set_tenant
    # ruleid: ruby-rails-misc-current-tenant-from-params
    Current.account = Account.find(params[:account_id])
  end

  def set_tenant_generic
    # ruleid: ruby-rails-misc-current-tenant-from-params
    Current.tenant = Organization.find(params[:org_id])
  end

  def set_tenant_safe
    # ok: ruby-rails-misc-current-tenant-from-params
    Current.account = current_user.account
  end
end
