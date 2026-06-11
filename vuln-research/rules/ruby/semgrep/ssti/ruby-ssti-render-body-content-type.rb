# Fixture for render body: with interpolation and an HTML content type.

class RawController
  def emit(params)
    # ruleid: ruby-ssti-render-body-content-type
    render(body: "<p>#{params[:msg]}</p>", content_type: "text/html")
  end

  def emit_safe(params)
    # ok: ruby-ssti-render-body-content-type
    render(body: params[:msg].to_s, content_type: "text/plain")
  end
end
