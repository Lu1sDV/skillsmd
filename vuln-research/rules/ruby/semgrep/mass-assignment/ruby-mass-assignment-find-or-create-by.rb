# Fixture for the find-or-create-by rule.

def lookup
  # ruleid: ruby-mass-assignment-find-or-create-by
  Tag.find_or_create_by(params[:tag])
end

def lookup_init
  # ruleid: ruby-mass-assignment-find-or-create-by
  Tag.find_or_initialize_by(params[:tag])
end

def lookup_safe
  # ok: ruby-mass-assignment-find-or-create-by
  Tag.find_or_create_by(name: params[:name].to_s.strip)
end
