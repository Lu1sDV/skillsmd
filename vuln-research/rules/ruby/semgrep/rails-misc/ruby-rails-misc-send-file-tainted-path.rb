# Fixture for tainted send_file path.

class AttachmentController < ApplicationController
  def download
    # ruleid: ruby-rails-misc-send-file-tainted-path
    send_file params[:path]
  end

  def download_interp
    # ruleid: ruby-rails-misc-send-file-tainted-path
    send_file "/var/data/#{params[:name]}.pdf"
  end

  def download_join
    # ruleid: ruby-rails-misc-send-file-tainted-path
    send_file Rails.root.join("storage", params[:name])
  end

  def download_safe
    name = File.basename(params[:name].to_s)
    path = Rails.root.join("storage", name)
    # ok: ruby-rails-misc-send-file-tainted-path
    send_file path.to_s if path.to_s.start_with?(Rails.root.join("storage").to_s)
  end
end
