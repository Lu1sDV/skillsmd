# Fixture for the File.truncate path-injection rule.

def shrink
  # ruleid: ruby-path-traversal-file-truncate
  File.truncate(params[:path], 0)
end

def shrink_named
  # ruleid: ruby-path-traversal-file-truncate
  File.truncate("/var/log/#{params[:name]}", 0)
end

def shrink_fixed
  # ok: ruby-path-traversal-file-truncate
  File.truncate("/var/log/app.log", 0)
end
