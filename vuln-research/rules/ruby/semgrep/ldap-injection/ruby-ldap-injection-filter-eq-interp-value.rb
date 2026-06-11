# Fixture exercising a typed LDAP filter assertion built from an interpolated value.

def find_user(params)
  # ruleid: ruby-ldap-injection-filter-eq-interp-value
  Net::LDAP::Filter.eq("cn", "#{params[:name]}*")
end

def safe_find_user(params)
  # ok: ruby-ldap-injection-filter-eq-interp-value
  Net::LDAP::Filter.eq("cn", Net::LDAP::Filter.escape(params[:name]))
end
