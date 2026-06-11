# Fixture exercising an LDAP bind DN assembled from interpolated input.

def connect(params)
  # ruleid: ruby-ldap-injection-bind-dn-interp
  Net::LDAP.new(host: "ldap.example.com", auth: { method: :simple, username: "uid=#{params[:user]},ou=people,dc=example,dc=com", password: params[:pw] })
end

def safe_connect(pw)
  # ok: ruby-ldap-injection-bind-dn-interp
  Net::LDAP.new(host: "ldap.example.com", auth: { method: :simple, username: "uid=admin,dc=example,dc=com", password: pw })
end
