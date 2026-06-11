# Fixture for a Tilt[...] engine fed a template body from request input.

class SnippetController
  def run(params)
    # ruleid: ruby-ssti-tilt-engine-bracket-param
    Tilt["erb"].new { params[:source] }.render(self)
  end

  def run_safe
    # ok: ruby-ssti-tilt-engine-bracket-param
    Tilt["erb"].new { "Static <%= name %>" }.render(self, name: "x")
  end
end
