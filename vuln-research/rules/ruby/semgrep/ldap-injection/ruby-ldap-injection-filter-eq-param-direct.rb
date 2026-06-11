# Fixture exercising a typed LDAP filter built straight from a request parameter.

def find(params)
  # ruleid: ruby-ldap-injection-filter-eq-param-direct
  Net::LDAP::Filter.eq("uid", params[:uid])
end

def safe_find(params)
  # ok: ruby-ldap-injection-filter-eq-param-direct
  Net::LDAP::Filter.eq("uid", Net::LDAP::Filter.escape(params[:uid]))
end
