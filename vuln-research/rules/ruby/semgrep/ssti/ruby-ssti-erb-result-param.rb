# Fixture for a request parameter compiled as a full ERB template.

class PreviewController
  def render_preview(params)
    # ruleid: ruby-ssti-erb-result-param
    ERB.new(params[:template]).result(binding)
  end

  def render_allowlisted(params)
    template = TEMPLATES.fetch(params[:key], "default")
    # ok: ruby-ssti-erb-result-param
    ERB.new(template).result(binding)
  end
end
