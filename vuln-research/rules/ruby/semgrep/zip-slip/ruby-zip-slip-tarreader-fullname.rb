require "rubygems/package"

def untar(io, dest)
  Gem::Package::TarReader.new(io) do |tar|
    tar.each do |entry|
      next unless entry.file?
      # ruleid: ruby-zip-slip-tarreader-fullname
      File.write(File.join(dest, entry.full_name), entry.read)
    end
  end
end

def untar_safe(io, dest)
  Gem::Package::TarReader.new(io) do |tar|
    tar.each do |entry|
      next unless entry.file?
      target = File.expand_path(entry.full_name, dest)
      next unless target.start_with?(File.expand_path(dest) + "/")
      # ok: ruby-zip-slip-tarreader-fullname
      File.write(target, entry.read)
    end
  end
end
