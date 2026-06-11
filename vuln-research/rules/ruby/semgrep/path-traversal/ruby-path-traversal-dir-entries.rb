# Fixture for the Dir.entries / Dir.children / Dir.foreach path-injection rule.

def browse
  # ruleid: ruby-path-traversal-dir-entries
  Dir.entries(params[:dir])
end

def browse_named
  # ruleid: ruby-path-traversal-dir-entries
  Dir.children("/srv/data/#{params[:folder]}")
end

def browse_fixed
  # ok: ruby-path-traversal-dir-entries
  Dir.entries("/srv/data/public")
end
