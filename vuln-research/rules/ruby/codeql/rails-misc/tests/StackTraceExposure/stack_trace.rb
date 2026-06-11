class ReportsController < ApplicationController

  # Unsafe: the exception backtrace is sent straight to the client.
  def generate
    build_report()
  rescue => e
    render body: e.backtrace, content_type: "text/plain"
  end

  # Safe: backtrace is logged server-side, client gets a generic message.
  def generate_safe
    build_report()
  rescue => e
    Rails.logger.error(e.backtrace)
    render body: "Report generation failed", content_type: "text/plain"
  end

end
