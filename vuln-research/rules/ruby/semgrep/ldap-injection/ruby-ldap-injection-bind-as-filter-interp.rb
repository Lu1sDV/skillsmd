# Fixture exercising Net::LDAP#bind_as with an interpolated filter.

def authenticate(ldap, params)
  # ruleid: ruby-ldap-injection-bind-as-filter-interp
  ldap.bind_as(base: "dc=example,dc=com", filter: "(uid=#{params[:user]})", password: params[:pw])
end

def safe_authenticate(ldap, params)
  flt = Net::LDAP::Filter.eq("uid", Net::LDAP::Filter.escape(params[:user]))
  # ok: ruby-ldap-injection-bind-as-filter-interp
  ldap.bind_as(base: "dc=example,dc=com", filter: flt, password: params[:pw])
end
