# Fixture exercising an LDAP search whose requested attributes come from params.

def run(ldap, params, filter)
  # ruleid: ruby-ldap-injection-attributes-tainted
  ldap.search(base: "dc=example,dc=com", filter: filter, attributes: [params[:attr]])
end

def safe_run(ldap, filter)
  # ok: ruby-ldap-injection-attributes-tainted
  ldap.search(base: "dc=example,dc=com", filter: filter, attributes: ["cn", "mail"])
end
