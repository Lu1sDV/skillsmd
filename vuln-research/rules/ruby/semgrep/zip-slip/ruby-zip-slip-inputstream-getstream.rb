require "zip"

def stream_extract(zip_path, dest)
  Zip::InputStream.open(zip_path) do |io|
    while (entry = io.get_next_entry)
      # ruleid: ruby-zip-slip-inputstream-getstream
      IO.copy_stream(io, File.join(dest, entry.name))
    end
  end
end

def stream_extract_safe(zip_path, dest)
  Zip::InputStream.open(zip_path) do |io|
    while (entry = io.get_next_entry)
      target = File.expand_path(entry.name, dest)
      next unless target.start_with?(File.expand_path(dest) + "/")
      # ok: ruby-zip-slip-inputstream-getstream
      IO.copy_stream(io, target)
    end
  end
end
