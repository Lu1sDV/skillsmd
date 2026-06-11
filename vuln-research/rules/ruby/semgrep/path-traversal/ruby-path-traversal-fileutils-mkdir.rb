# Fixture for the FileUtils.mkdir / mkdir_p path-injection rule.

def provision
  # ruleid: ruby-path-traversal-fileutils-mkdir
  FileUtils.mkdir_p(params[:path])
end

def provision_named
  # ruleid: ruby-path-traversal-fileutils-mkdir
  FileUtils.mkdir("/srv/tenants/#{params[:tenant]}")
end

def provision_fixed
  # ok: ruby-path-traversal-fileutils-mkdir
  FileUtils.mkdir_p("/srv/tenants/default")
end
