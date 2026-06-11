# Fixture for the Dir.chdir path-injection rule.

def enter_workspace
  # ruleid: ruby-path-traversal-dir-chdir
  Dir.chdir(params[:dir])
end

def enter_named
  # ruleid: ruby-path-traversal-dir-chdir
  Dir.chdir("/srv/work/#{params[:project]}")
end

def enter_fixed
  # ok: ruby-path-traversal-dir-chdir
  Dir.chdir("/srv/work/default")
end
