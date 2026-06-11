require "zip"

def restore(archive, entry, dest)
  # ruleid: ruby-zip-slip-rubyzip-extract-default
  archive.extract(entry, "#{dest}/#{entry.name}")
end

def restore_checked(archive, entry, dest)
  safe = File.expand_path(entry.name, dest)
  raise "escape" unless safe.start_with?(File.expand_path(dest))
  # ok: ruby-zip-slip-rubyzip-extract-default
  archive.extract(entry, safe)
end
