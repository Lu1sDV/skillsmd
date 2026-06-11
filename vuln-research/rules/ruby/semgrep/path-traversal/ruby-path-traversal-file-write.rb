# Fixture for the File.write path-injection rule.

def save_upload(content)
  # ruleid: ruby-path-traversal-file-write
  File.write(params[:dest], content)
end

def save_named(content)
  # ruleid: ruby-path-traversal-file-write
  File.write("/var/data/#{params[:key]}", content)
end

def save_fixed(content)
  # ok: ruby-path-traversal-file-write
  File.write("/var/data/state.json", content)
end
