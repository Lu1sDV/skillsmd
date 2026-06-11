# Fixture for Rails inline rendering of an interpolated template string.

class PagesController
  def show(params)
    # ruleid: ruby-ssti-render-inline
    render(inline: "Welcome #{params[:name]}")
  end

  def show_locals(params)
    # ok: ruby-ssti-render-inline
    render(inline: "Welcome <%= name %>", locals: { name: params[:name] })
  end
end
