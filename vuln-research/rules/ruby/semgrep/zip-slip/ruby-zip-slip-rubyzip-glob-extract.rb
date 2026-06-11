require "zip"

def extract_concat(entry, dest)
  # ruleid: ruby-zip-slip-rubyzip-glob-extract
  entry.extract(dest + "/" + entry.name)
end

def extract_validated(entry, dest)
  target = File.expand_path(entry.name, dest)
  raise unless target.start_with?(File.expand_path(dest) + "/")
  # ok: ruby-zip-slip-rubyzip-glob-extract
  entry.extract(target)
end
