# Fixture for the interpolated recipient header detector.

class NotifyMailer < ApplicationMailer
  def welcome
    # ruleid: ruby-mail-header-injection-mail-to-interp
    mail(to: "#{params[:email]}", subject: "Hi")
  end

  def welcome_safe
    # ok: ruby-mail-header-injection-mail-to-interp
    mail(to: user.email, subject: "Hi")
  end
end
