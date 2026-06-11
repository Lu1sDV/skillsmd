# Fixture exercising an ActiveDirectory user lookup with an interpolated filter.

def lookup(params)
  # ruleid: ruby-ldap-injection-activedirectory-filter-interp
  ActiveDirectory::User.find(:all, filter: "(sAMAccountName=#{params[:login]})")
end

def safe_lookup(safe_filter)
  # ok: ruby-ldap-injection-activedirectory-filter-interp
  ActiveDirectory::User.find(:all, filter: safe_filter)
end
