# Fixture for manual Location header writes.

class DownloadController < ApplicationController
  def fetch
    # ruleid: ruby-open-redirect-location-header
    headers["Location"] = params[:url]
    head :found
  end

  def fetch_interp
    # ruleid: ruby-open-redirect-location-header
    headers["Location"] = "https://#{params[:cdn]}/file"
    head :found
  end

  def safe_fetch
    # ok: ruby-open-redirect-location-header
    headers["Location"] = "/files/report.pdf"
    head :found
  end
end
