# Fixture for a request parameter parsed directly as a Liquid template.

class TemplatesController
  def preview(params)
    # ruleid: ruby-ssti-liquid-parse-param
    Liquid::Template.parse(params[:body]).render(assigns)
  end

  def preview_safe(params)
    body = STORED_TEMPLATES.fetch(params[:id], "")
    # ok: ruby-ssti-liquid-parse-param
    Liquid::Template.parse(body).render(assigns)
  end
end
