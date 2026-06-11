# Fixture exercising ldap.search with an interpolated string filter.

def run_search(ldap, params)
  # ruleid: ruby-ldap-injection-search-filter-interp
  ldap.search(base: "ou=people,dc=example,dc=com", filter: "(uid=#{params[:uid]})")
end

def safe_run_search(ldap, params)
  safe = Net::LDAP::Filter.eq("uid", Net::LDAP::Filter.escape(params[:uid]))
  # ok: ruby-ldap-injection-search-filter-interp
  ldap.search(base: "ou=people,dc=example,dc=com", filter: safe)
end
