# Fixture for the FileUtils.cp / cp_r / mv path-injection rule.

def copy_in
  # ruleid: ruby-path-traversal-fileutils-copy
  FileUtils.cp(params[:src], "/srv/store/out")
end

def copy_to_named
  # ruleid: ruby-path-traversal-fileutils-copy
  FileUtils.mv("/tmp/in", "/srv/store/#{params[:name]}")
end

def copy_fixed
  # ok: ruby-path-traversal-fileutils-copy
  FileUtils.cp("/tmp/in", "/srv/store/out")
end
