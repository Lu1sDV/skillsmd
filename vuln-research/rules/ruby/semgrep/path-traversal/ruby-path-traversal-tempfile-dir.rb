# Fixture for the Tempfile / Dir.mktmpdir prefix-and-dir path-injection rule.

def scratch
  # ruleid: ruby-path-traversal-tempfile-dir
  Tempfile.new(params[:prefix])
end

def scratch_dir
  # ruleid: ruby-path-traversal-tempfile-dir
  Dir.mktmpdir("job-", params[:base])
end

def scratch_fixed
  # ok: ruby-path-traversal-tempfile-dir
  Tempfile.new("job-", "/tmp")
end
