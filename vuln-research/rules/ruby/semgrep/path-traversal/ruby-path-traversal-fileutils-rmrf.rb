# Fixture for the FileUtils.rm_rf / rm / rm_r path-injection rule.

def purge
  # ruleid: ruby-path-traversal-fileutils-rmrf
  FileUtils.rm_rf(params[:dir])
end

def purge_named
  # ruleid: ruby-path-traversal-fileutils-rmrf
  FileUtils.rm_rf("/srv/cache/#{params[:bucket]}")
end

def purge_fixed
  # ok: ruby-path-traversal-fileutils-rmrf
  FileUtils.rm_rf("/srv/cache/tmp")
end
