# Fixture for the Dir.glob / Dir[] path-injection rule.

def list_user_files
  # ruleid: ruby-path-traversal-dir-glob
  Dir.glob(params[:pattern])
end

def list_named
  # ruleid: ruby-path-traversal-dir-glob
  Dir["/srv/files/#{params[:sub]}/*"]
end

def list_fixed
  # ok: ruby-path-traversal-dir-glob
  Dir.glob("/srv/files/*.txt")
end
