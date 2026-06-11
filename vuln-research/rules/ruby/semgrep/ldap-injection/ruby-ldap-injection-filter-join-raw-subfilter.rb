# Fixture exercising a composite LDAP filter with a raw interpolated sub-filter.

def build(params)
  base = Net::LDAP::Filter.eq("objectClass", "person")
  # ruleid: ruby-ldap-injection-filter-join-raw-subfilter
  base & Net::LDAP::Filter.construct("(cn=#{params[:cn]})")
end

def safe_build(params)
  base = Net::LDAP::Filter.eq("objectClass", "person")
  # ok: ruby-ldap-injection-filter-join-raw-subfilter
  base & Net::LDAP::Filter.eq("cn", Net::LDAP::Filter.escape(params[:cn]))
end
