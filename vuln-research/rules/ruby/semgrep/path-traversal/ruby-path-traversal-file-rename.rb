# Fixture for the File.rename path-injection rule.

def move_upload
  # ruleid: ruby-path-traversal-file-rename
  File.rename(params[:from], "/srv/store/final")
end

def move_to_named
  # ruleid: ruby-path-traversal-file-rename
  File.rename("/tmp/incoming", "/srv/store/#{params[:name]}")
end

def move_fixed
  # ok: ruby-path-traversal-file-rename
  File.rename("/tmp/incoming", "/srv/store/final")
end
