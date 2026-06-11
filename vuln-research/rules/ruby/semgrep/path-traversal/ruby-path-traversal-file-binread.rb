# Fixture for the File.binread path-injection rule.

def fetch_blob
  # ruleid: ruby-path-traversal-file-binread
  File.binread(params[:blob])
end

def fetch_named_blob
  # ruleid: ruby-path-traversal-file-binread
  File.binread("/srv/blobs/#{params[:id]}")
end

def fetch_fixed_blob
  # ok: ruby-path-traversal-file-binread
  File.binread("/srv/blobs/default.bin")
end
