# Fixture for the File.open path-injection rule.

def stream_file
  # ruleid: ruby-path-traversal-file-open
  File.open(params[:path], "r") { |f| f.read }
end

def stream_named
  # ruleid: ruby-path-traversal-file-open
  File.open("/srv/files/#{params[:doc]}")
end

def stream_fixed
  # ok: ruby-path-traversal-file-open
  File.open("/srv/files/manifest.txt", "r")
end
