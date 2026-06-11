require "minitar"

def extract_tar(uploaded_path, dest)
  # ruleid: ruby-zip-slip-minitar-unpack
  Minitar.unpack(uploaded_path, dest)
end

def extract_tar_filtered(uploaded_path, dest)
  safe_names = []
  Minitar.open(uploaded_path) do |tar|
    tar.each { |e| safe_names << e.full_name if File.expand_path(e.full_name, dest).start_with?(File.expand_path(dest) + "/") }
  end
  # ok: ruby-zip-slip-minitar-unpack
  Minitar.unpack(uploaded_path, dest, safe_names)
end
