# Fixture for tainted send_data filename header construction.

class DownloadController < ApplicationController
  def export
    # ruleid: ruby-rails-misc-send-data-tainted-filename
    send_data report_bytes, filename: params[:name], type: "text/csv"
  end

  def export_chained
    # ruleid: ruby-rails-misc-send-data-tainted-filename
    send_data report_bytes, filename: params[:name].to_s
  end

  def export_safe
    safe = File.basename(params[:name].to_s.gsub(/[^a-z0-9_.-]/i, ""))
    # ok: ruby-rails-misc-send-data-tainted-filename
    send_data report_bytes, filename: safe, type: "text/csv"
  end
end
