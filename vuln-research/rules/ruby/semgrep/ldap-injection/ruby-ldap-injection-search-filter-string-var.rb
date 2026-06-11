# Fixture exercising an LDAP search fed a String filter via an intermediate variable.

def run(ldap, params)
  # ruleid: ruby-ldap-injection-search-filter-string-var
  q = "(cn=#{params[:name]})"
  ldap.search(base: "dc=example,dc=com", filter: q)
end

def safe_run(ldap, params)
  q = Net::LDAP::Filter.eq("cn", Net::LDAP::Filter.escape(params[:name]))
  # ok: ruby-ldap-injection-search-filter-string-var
  ldap.search(base: "dc=example,dc=com", filter: q)
end
