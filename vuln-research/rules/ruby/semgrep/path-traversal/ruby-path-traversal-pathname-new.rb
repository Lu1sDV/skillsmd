# Fixture for the Pathname.new(...).read/write path-injection rule.

def pn_read
  # ruleid: ruby-path-traversal-pathname-new
  Pathname.new(params[:file]).read
end

def pn_write(data)
  # ruleid: ruby-path-traversal-pathname-new
  Pathname.new("/srv/data/#{params[:name]}").write(data)
end

def pn_fixed
  # ok: ruby-path-traversal-pathname-new
  Pathname.new("/srv/data/config.yml").read
end
