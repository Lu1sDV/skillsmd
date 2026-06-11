# Fixture covering send_data served as active HTML.

def download
  # ruleid: ruby-xss-send-data-html
  send_data(params[:doc], type: "text/html", disposition: "inline")
end

def download_attachment
  # ok: ruby-xss-send-data-html
  send_data(params[:doc], type: "application/octet-stream", disposition: "attachment")
end
