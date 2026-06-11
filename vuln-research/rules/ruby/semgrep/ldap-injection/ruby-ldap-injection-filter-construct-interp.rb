# Fixture exercising Net::LDAP::Filter.construct with a raw, interpolated filter.

def lookup(params)
  # ruleid: ruby-ldap-injection-filter-construct-interp
  Net::LDAP::Filter.construct("(uid=#{params[:uid]})")
end

def safe_lookup(params)
  # ok: ruby-ldap-injection-filter-construct-interp
  Net::LDAP::Filter.eq("uid", Net::LDAP::Filter.escape(params[:uid]))
end
