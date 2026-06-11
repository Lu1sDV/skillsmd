# Fixture for the File.symlink path-injection rule.

def link_target
  # ruleid: ruby-path-traversal-file-symlink
  File.symlink(params[:target], "/srv/links/current")
end

def link_named
  # ruleid: ruby-path-traversal-file-symlink
  File.symlink("/srv/data/active", "/srv/links/#{params[:alias]}")
end

def link_fixed
  # ok: ruby-path-traversal-file-symlink
  File.symlink("/srv/data/active", "/srv/links/current")
end
