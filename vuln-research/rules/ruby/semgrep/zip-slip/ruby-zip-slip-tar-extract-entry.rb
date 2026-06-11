require "rubygems/package"

def extract_member(entry, dest)
  # ruleid: ruby-zip-slip-tar-extract-entry
  File.open(File.join(dest, entry.full_name), "wb") { |f| f.write(entry.read) }
end

def extract_member_safe(entry, dest)
  dst = File.expand_path(entry.full_name, dest)
  raise unless dst.start_with?(File.expand_path(dest) + "/")
  # ok: ruby-zip-slip-tar-extract-entry
  File.open(dst, "wb") { |f| f.write(entry.read) }
end
