# Fixture for the Dir.mkdir / Dir.rmdir path-injection rule.

def make_bucket
  # ruleid: ruby-path-traversal-dir-mkdir
  Dir.mkdir(params[:bucket])
end

def drop_named
  # ruleid: ruby-path-traversal-dir-mkdir
  Dir.rmdir("/srv/buckets/#{params[:name]}")
end

def make_fixed
  # ok: ruby-path-traversal-dir-mkdir
  Dir.mkdir("/srv/buckets/inbox")
end
