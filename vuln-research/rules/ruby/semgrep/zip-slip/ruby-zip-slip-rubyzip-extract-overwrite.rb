require "zip"

def configure_overwrite
  # ruleid: ruby-zip-slip-rubyzip-extract-overwrite
  Zip.on_exists_proc = true
end

def configure_safe
  # ok: ruby-zip-slip-rubyzip-extract-overwrite
  Zip.on_exists_proc = false
end
