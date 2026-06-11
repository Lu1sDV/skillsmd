# Fixture for the File.delete / File.unlink path-injection rule.

def remove_doc
  # ruleid: ruby-path-traversal-file-delete
  File.delete(params[:doc])
end

def remove_named
  # ruleid: ruby-path-traversal-file-delete
  File.unlink("/tmp/cache/#{params[:key]}")
end

def remove_fixed
  # ok: ruby-path-traversal-file-delete
  File.delete("/tmp/cache/lock")
end
