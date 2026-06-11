require "zip"

def write_entry(entry, dest)
  # ruleid: ruby-zip-slip-fileutils-write-entry
  File.open(File.join(dest, entry.name), "wb") do |f|
    f.write(entry.get_input_stream.read)
  end
end

def write_entry_checked(entry, dest)
  target = File.expand_path(entry.name, dest)
  raise unless target.start_with?(File.expand_path(dest) + "/")
  # ok: ruby-zip-slip-fileutils-write-entry
  File.open(target, "wb") do |f|
    f.write(entry.get_input_stream.read)
  end
end
