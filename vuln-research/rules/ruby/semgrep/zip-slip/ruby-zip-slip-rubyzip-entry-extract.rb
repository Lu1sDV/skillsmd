require "zip"

def unzip_unsafe(zip_path, dest_dir)
  Zip::File.open(zip_path) do |archive|
    archive.each do |entry|
      # ruleid: ruby-zip-slip-rubyzip-entry-extract
      entry.extract(File.join(dest_dir, entry.name))
    end
  end
end

def unzip_safe(zip_path, dest_dir)
  Zip::File.open(zip_path) do |archive|
    archive.each do |entry|
      target = File.expand_path(File.join(dest_dir, entry.name))
      next unless target.start_with?(File.expand_path(dest_dir) + File::SEPARATOR)
      # ok: ruby-zip-slip-rubyzip-entry-extract
      entry.extract(target)
    end
  end
end
