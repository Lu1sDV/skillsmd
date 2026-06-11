require "zip"

def place_entry(entry)
  # ruleid: ruby-zip-slip-absolute-entry-name
  File.write(File.expand_path(entry.name), entry.get_input_stream.read)
end

def place_entry_based(entry, dest)
  target = File.expand_path(entry.name, dest)
  raise unless target.start_with?(File.expand_path(dest) + "/")
  # ok: ruby-zip-slip-absolute-entry-name
  File.write(target, entry.get_input_stream.read)
end
