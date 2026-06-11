# Fixture: selecting the tenant from a client header versus from the session subject.

class TenantResolver
  def resolve(request)
    # ruleid: ruby-http-parsing-tenant-from-header
    Current.tenant = Tenant.find_by(slug: request.headers["X-Tenant"])
  end

  def resolve_from_session(user)
    # ok: ruby-http-parsing-tenant-from-header
    Current.tenant = user.tenant
  end
end
