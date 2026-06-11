# Fixture for a render path assembled by interpolating request input.

class ArticleController < ApplicationController
  def show
    # ruleid: ruby-render-injection-interpolated-template
    render "articles/#{params[:view]}"
  end

  def show_template
    # ruleid: ruby-render-injection-interpolated-template
    render template: "articles/#{params[:view]}"
  end

  def safe_show
    # ok: ruby-render-injection-interpolated-template
    render "articles/show"
  end
end
