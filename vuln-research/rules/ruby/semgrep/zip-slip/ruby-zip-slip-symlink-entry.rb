require "rubygems/package"

def restore_symlink(entry, dest)
  # ruleid: ruby-zip-slip-symlink-entry
  File.symlink(entry.header.linkname, File.join(dest, entry.full_name))
end

def restore_symlink_safe(entry, dest)
  return if entry.symlink?
  # ok: ruby-zip-slip-symlink-entry
  File.write(File.expand_path(entry.full_name, dest), entry.read)
end
