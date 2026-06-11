# Fixture exercising a range LDAP filter assertion built from interpolated input.

def by_uid_number(params)
  # ruleid: ruby-ldap-injection-filter-range-interp
  Net::LDAP::Filter.ge("uidNumber", "#{params[:min]}")
end

def safe_by_uid_number(params)
  # ok: ruby-ldap-injection-filter-range-interp
  Net::LDAP::Filter.ge("uidNumber", Net::LDAP::Filter.escape(params[:min]))
end
