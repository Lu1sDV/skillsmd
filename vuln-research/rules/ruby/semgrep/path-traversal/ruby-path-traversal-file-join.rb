# Fixture for the File.join-then-read path-injection rule.

BASE = "/srv/files"

def join_read
  # ruleid: ruby-path-traversal-file-join
  File.read(File.join(BASE, params[:name]))
end

def join_open
  # ruleid: ruby-path-traversal-file-join
  File.open(File.join(BASE, params[:sub], "data.txt"))
end

def join_fixed
  # ok: ruby-path-traversal-file-join
  File.read(File.join(BASE, "index.txt"))
end
