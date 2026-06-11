# Fixture exercising an LDAP filter built by string concatenation.

def search(params)
  # ruleid: ruby-ldap-injection-filter-string-concat
  Net::LDAP::Filter.construct("(uid=" + params[:uid] + ")")
end

def safe_search(params)
  # ok: ruby-ldap-injection-filter-string-concat
  Net::LDAP::Filter.eq("uid", Net::LDAP::Filter.escape(params[:uid]))
end
