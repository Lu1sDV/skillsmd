# Fixture for render html: built by interpolation and marked html_safe.

class NoticeController
  def show(params)
    # ruleid: ruby-ssti-render-html-interp
    render(html: "<div>#{params[:body]}</div>".html_safe)
  end

  def show_safe(params)
    # ok: ruby-ssti-render-html-interp
    render(html: params[:body].to_s)
  end
end
