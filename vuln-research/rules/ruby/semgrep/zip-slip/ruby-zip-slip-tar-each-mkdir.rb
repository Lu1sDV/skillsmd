require "fileutils"
require "rubygems/package"

def make_tar_dir(entry, dest)
  # ruleid: ruby-zip-slip-tar-each-mkdir
  FileUtils.mkdir_p(File.join(dest, entry.full_name))
end

def make_tar_dir_safe(entry, dest)
  target = File.expand_path(entry.full_name, dest)
  raise unless target.start_with?(File.expand_path(dest) + "/")
  # ok: ruby-zip-slip-tar-each-mkdir
  FileUtils.mkdir_p(target)
end
