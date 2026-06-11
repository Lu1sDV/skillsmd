# Fixture exercising an LDAP base DN built by string concatenation.

def run(ldap, params, filter)
  # ruleid: ruby-ldap-injection-base-dn-concat
  ldap.search(base: "ou=" + params[:ou] + ",dc=example,dc=com", filter: filter)
end

def safe_run(ldap, filter)
  # ok: ruby-ldap-injection-base-dn-concat
  ldap.search(base: "ou=people,dc=example,dc=com", filter: filter)
end
