# Fixture for the Pathname.new(...).open/delete path-injection rule.

def pn_open
  # ruleid: ruby-path-traversal-pathname-open
  Pathname.new(params[:file]).open("r")
end

def pn_delete
  # ruleid: ruby-path-traversal-pathname-open
  Pathname.new("/srv/data/#{params[:name]}").delete
end

def pn_open_fixed
  # ok: ruby-path-traversal-pathname-open
  Pathname.new("/srv/data/state.bin").open("r")
end
