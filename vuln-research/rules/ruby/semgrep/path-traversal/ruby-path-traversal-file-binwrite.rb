# Fixture for the File.binwrite path-injection rule.

def store_bytes(bytes)
  # ruleid: ruby-path-traversal-file-binwrite
  File.binwrite(params[:target], bytes)
end

def store_named_bytes(bytes)
  # ruleid: ruby-path-traversal-file-binwrite
  File.binwrite("/srv/up/#{params[:name]}", bytes)
end

def store_fixed_bytes(bytes)
  # ok: ruby-path-traversal-file-binwrite
  File.binwrite("/srv/up/latest.bin", bytes)
end
