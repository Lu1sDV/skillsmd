# Fixture for the Rails send_file path-injection rule.

def download
  # ruleid: ruby-path-traversal-send-file
  send_file(params[:path])
end

def download_named
  # ruleid: ruby-path-traversal-send-file
  send_file("/srv/downloads/#{params[:file]}", disposition: "attachment")
end

def download_fixed
  # ok: ruby-path-traversal-send-file
  send_file("/srv/downloads/report.pdf", disposition: "attachment")
end
