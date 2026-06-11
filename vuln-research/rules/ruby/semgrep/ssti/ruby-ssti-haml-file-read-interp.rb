# Fixture for Haml compiled from a file path supplied by request input.

class ThemeController
  def preview(params)
    # ruleid: ruby-ssti-haml-file-read-interp
    Haml::Engine.new(File.read(params[:theme])).render
  end

  def preview_safe
    # ok: ruby-ssti-haml-file-read-interp
    Haml::Engine.new(File.read("themes/default.haml")).render
  end
end
