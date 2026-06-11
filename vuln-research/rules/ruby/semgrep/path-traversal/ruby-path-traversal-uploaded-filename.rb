# Fixture for the UploadedFile#original_filename path-injection rule.

def store_upload(upload)
  # ruleid: ruby-path-traversal-uploaded-filename
  File.write("/srv/uploads/#{upload.original_filename}", upload.read)
end

def store_upload_join(upload)
  # ruleid: ruby-path-traversal-uploaded-filename
  path = File.join("/srv/uploads", upload.original_filename)
  File.binwrite(path, upload.read)
end

def store_upload_safe(upload)
  # ok: ruby-path-traversal-uploaded-filename
  File.write("/srv/uploads/#{SecureRandom.uuid}", upload.read)
end
