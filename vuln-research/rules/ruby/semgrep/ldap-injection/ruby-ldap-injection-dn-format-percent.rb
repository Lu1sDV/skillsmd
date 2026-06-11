# Fixture exercising an LDAP filter built with the percent format operator.

def search(params)
  # ruleid: ruby-ldap-injection-dn-format-percent
  Net::LDAP::Filter.construct("(uid=%s)" % params[:uid])
end

def safe_search(params)
  # ok: ruby-ldap-injection-dn-format-percent
  Net::LDAP::Filter.eq("uid", Net::LDAP::Filter.escape(params[:uid]))
end
