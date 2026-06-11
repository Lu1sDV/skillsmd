# Fixture for render file: built with File.join from request input.

class DocsController < ApplicationController
  def show
    # ruleid: ruby-render-injection-file-join-params
    render file: File.join(Rails.root, "docs", params[:doc])
  end

  def safe_show
    # ok: ruby-render-injection-file-join-params
    render file: File.join(Rails.root, "docs", "index.html")
  end
end
