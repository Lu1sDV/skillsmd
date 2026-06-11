class DocumentsController < ApplicationController
  def import
    raw = params[:doc]
    # JSON.load honours json_class -> arbitrary object instantiation from input.
    doc = JSON.load(raw)
    render plain: doc.inspect
  end

  def safe_import
    raw = params[:doc]
    # JSON.parse never instantiates arbitrary classes.
    doc = JSON.parse(raw)
    render plain: doc.inspect
  end
end
