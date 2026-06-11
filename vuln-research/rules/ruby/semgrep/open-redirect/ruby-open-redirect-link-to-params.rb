# Fixture for link_to with a tainted href.

module LinkHelper
  def continue_link
    # ruleid: ruby-open-redirect-link-to-params
    link_to("Continue", params[:next])
  end

  def continue_link_opts
    # ruleid: ruby-open-redirect-link-to-params
    link_to("Continue", params[:url], class: "btn")
  end

  def safe_link
    # ok: ruby-open-redirect-link-to-params
    link_to("Home", root_path)
  end
end
