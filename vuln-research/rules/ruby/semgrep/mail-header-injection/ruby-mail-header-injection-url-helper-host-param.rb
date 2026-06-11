# Fixture for the URL helper host-poisoning detector.

class PasswordMailer < ApplicationMailer
  def reset
    # ruleid: ruby-mail-header-injection-url-helper-host-param
    @link = edit_password_reset_url(token, host: request.host)
    mail(to: user.email)
  end

  def reset_param
    # ruleid: ruby-mail-header-injection-url-helper-host-param
    @link = edit_password_reset_url(token, host: params[:host])
    mail(to: user.email)
  end

  def reset_safe
    # ok: ruby-mail-header-injection-url-helper-host-param
    @link = edit_password_reset_url(token, host: "app.example.com")
    mail(to: user.email)
  end
end
