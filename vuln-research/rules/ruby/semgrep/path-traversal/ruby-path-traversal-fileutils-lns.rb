# Fixture for the FileUtils.ln_s path-injection rule.

def alias_release
  # ruleid: ruby-path-traversal-fileutils-lns
  FileUtils.ln_s(params[:target], "/srv/links/current")
end

def alias_named
  # ruleid: ruby-path-traversal-fileutils-lns
  FileUtils.ln_s("/srv/releases/active", "/srv/links/#{params[:alias]}")
end

def alias_fixed
  # ok: ruby-path-traversal-fileutils-lns
  FileUtils.ln_s("/srv/releases/active", "/srv/links/current")
end
