# Fixture exercising ldap.search with an interpolated base DN.

def run_search(ldap, params, filter)
  # ruleid: ruby-ldap-injection-search-base-dn-interp
  ldap.search(base: "ou=people,dc=#{params[:dc]},dc=com", filter: filter)
end

def safe_run_search(ldap, filter)
  # ok: ruby-ldap-injection-search-base-dn-interp
  ldap.search(base: "ou=people,dc=example,dc=com", filter: filter)
end
