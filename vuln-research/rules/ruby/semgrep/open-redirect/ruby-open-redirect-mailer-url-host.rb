# Fixture for mailer URL helpers with a tainted host option.

class UserMailer < ApplicationMailer
  def confirmation(user)
    # ruleid: ruby-open-redirect-mailer-url-host
    @link = confirm_account_url(user.token, host: params[:host])
    mail(to: user.email)
  end

  def reset(user)
    # ruleid: ruby-open-redirect-mailer-url-host
    @link = edit_password_url(user.token, host: request.host)
    mail(to: user.email)
  end

  def invite_safe(user)
    # ok: ruby-open-redirect-mailer-url-host
    @link = accept_invite_url(user.token, host: "app.example.com")
    mail(to: user.email)
  end
end
