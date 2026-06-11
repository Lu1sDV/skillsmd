# Fixture for render file: with a Pathname built from request input.

class ManualController < ApplicationController
  def page
    # ruleid: ruby-render-injection-pathname-file
    render file: Pathname.new(params[:path])
  end

  def safe_page
    # ok: ruby-render-injection-pathname-file
    render file: Pathname.new("public/manual/index.html")
  end
end
