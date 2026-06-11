# Fixture: setting the download filename from a client header versus a sanitized name.

class DownloadsController
  def grab
    # ruleid: ruby-http-parsing-send-data-header-from-request
    send_data blob, filename: request.headers["X-Filename"], type: "application/pdf"
  end

  def grab_safe
    # ok: ruby-http-parsing-send-data-header-from-request
    send_data blob, filename: "report.pdf", type: "application/pdf"
  end
end
