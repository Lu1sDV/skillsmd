# Fixture for conditional GET validators sourced from request data.
# Flagged calls use a param-derived validator; safe call uses the record.

class ArticlesController < ApplicationController
  def show
    @article = Article.find(params[:id])
    # ruleid: ruby-cache-poisoning-conditional-get-tainted-etag
    fresh_when(etag: params[:client_etag])
  end

  def edit
    @article = Article.find(params[:id])
    # ruleid: ruby-cache-poisoning-conditional-get-tainted-etag
    stale?(etag: params[:tag])
  end

  def safe_show
    @article = Article.find(params[:id])
    # ok: ruby-cache-poisoning-conditional-get-tainted-etag
    fresh_when(@article)
  end
end
