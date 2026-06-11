require "zip"

def dump_entry(entry, dest)
  # ruleid: ruby-zip-slip-binwrite-entry
  File.binwrite(File.join(dest, entry.name), entry.get_input_stream.read)
end

def dump_entry_safe(entry, dest)
  target = File.expand_path(entry.name, dest)
  raise unless target.start_with?(File.expand_path(dest) + "/")
  # ok: ruby-zip-slip-binwrite-entry
  File.binwrite(target, entry.get_input_stream.read)
end
