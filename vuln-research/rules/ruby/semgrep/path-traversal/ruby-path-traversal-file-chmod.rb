# Fixture for the File.chmod path-injection rule.

def relax_perms
  # ruleid: ruby-path-traversal-file-chmod
  File.chmod(0644, params[:path])
end

def relax_named
  # ruleid: ruby-path-traversal-file-chmod
  File.chmod(0600, "/srv/keys/#{params[:name]}")
end

def relax_fixed
  # ok: ruby-path-traversal-file-chmod
  File.chmod(0600, "/srv/keys/server.pem")
end
