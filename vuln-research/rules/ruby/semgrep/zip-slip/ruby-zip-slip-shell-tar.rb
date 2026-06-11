def extract_with_tar(archive, dest)
  # ruleid: ruby-zip-slip-shell-tar
  system("tar -xzf #{archive} -C #{dest}")
end

def extract_with_tar_guarded(archive, dest)
  # ok: ruby-zip-slip-shell-tar
  system("tar", "--no-absolute-names", "-xzf", archive, "-C", dest)
end
