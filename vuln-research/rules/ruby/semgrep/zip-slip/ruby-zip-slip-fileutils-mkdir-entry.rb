require "fileutils"
require "zip"

def make_dirs(entry, dest)
  # ruleid: ruby-zip-slip-fileutils-mkdir-entry
  FileUtils.mkdir_p(File.join(dest, entry.name))
end

def make_dirs_safe(entry, dest)
  target = File.expand_path(entry.name, dest)
  raise unless target.start_with?(File.expand_path(dest) + "/")
  # ok: ruby-zip-slip-fileutils-mkdir-entry
  FileUtils.mkdir_p(target)
end
