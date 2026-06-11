# Fixture exercising a fully attacker-supplied RFC 2254 filter expression.

def search(ldap, params)
  # ruleid: ruby-ldap-injection-filter-from-rfc2254
  flt = Net::LDAP::Filter.construct(params[:filter])
  ldap.search(filter: flt)
end

def safe_search(ldap, params)
  # ok: ruby-ldap-injection-filter-from-rfc2254
  flt = Net::LDAP::Filter.eq("uid", Net::LDAP::Filter.escape(params[:uid]))
  ldap.search(filter: flt)
end
