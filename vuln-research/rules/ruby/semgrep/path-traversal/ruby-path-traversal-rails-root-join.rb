# Fixture for the Rails.root.join-then-read path-injection rule.

def root_read
  # ruleid: ruby-path-traversal-rails-root-join
  File.read(Rails.root.join("public", params[:asset]))
end

def root_open
  # ruleid: ruby-path-traversal-rails-root-join
  File.open(Rails.root.join("storage", params[:key]))
end

def root_fixed
  # ok: ruby-path-traversal-rails-root-join
  File.read(Rails.root.join("public", "robots.txt"))
end
