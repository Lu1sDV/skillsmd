require "rubygems/package"

def restore_hardlink(entry, dest)
  # ruleid: ruby-zip-slip-hardlink-entry
  File.link(entry.header.linkname, File.join(dest, entry.full_name))
end

def restore_regular(entry, dest)
  return if entry.header.typeflag == "1"
  # ok: ruby-zip-slip-hardlink-entry
  File.write(File.expand_path(entry.full_name, dest), entry.read)
end
