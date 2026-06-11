# Fixture for the render file: option built from request input.

class DownloadController < ApplicationController
  def raw
    # ruleid: ruby-render-injection-file-option
    render file: params[:path]
  end

  def raw_layout
    # ruleid: ruby-render-injection-file-option
    render file: params[:path], layout: false
  end

  def safe_raw
    # ok: ruby-render-injection-file-option
    render file: Rails.root.join("public", "404.html")
  end
end
