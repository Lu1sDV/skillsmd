def unzip_to(archive, dest)
  # ruleid: ruby-zip-slip-shell-unzip
  system("unzip -o #{archive} -d #{dest}")
end

def unzip_listing(archive)
  # ok: ruby-zip-slip-shell-unzip
  system("file", archive)
end
