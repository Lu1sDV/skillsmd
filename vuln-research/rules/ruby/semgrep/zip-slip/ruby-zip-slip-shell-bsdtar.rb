def extract_7z(archive, dest)
  # ruleid: ruby-zip-slip-shell-bsdtar
  system("7z x #{archive} -o#{dest}")
end

def probe(archive)
  # ok: ruby-zip-slip-shell-bsdtar
  system("stat #{archive}")
end
