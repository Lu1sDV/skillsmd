# Fixture for button_to with a tainted action URL.

module FormHelper
  def submit_button
    # ruleid: ruby-open-redirect-button-to-params
    button_to("Send", params[:action_url])
  end

  def submit_button_opts
    # ruleid: ruby-open-redirect-button-to-params
    button_to("Send", params[:url], method: :post)
  end

  def safe_button
    # ok: ruby-open-redirect-button-to-params
    button_to("Delete", post_path(@post), method: :delete)
  end
end
