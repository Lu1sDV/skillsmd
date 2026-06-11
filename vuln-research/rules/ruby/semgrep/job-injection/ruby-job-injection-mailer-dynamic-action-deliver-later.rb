# Fixture for dynamic mailer action dispatched asynchronously.
# Flagged lines forward a params method name to public_send/send; safe line names the action.

class MailController < ApplicationController
  def notify
    # ruleid: ruby-job-injection-mailer-dynamic-action-deliver-later
    UserMailer.public_send(params[:action], current_user).deliver_later

    # ruleid: ruby-job-injection-mailer-dynamic-action-deliver-later
    UserMailer.send(params[:action], current_user).deliver_later(wait: 5.minutes)
  end

  def notify_safe
    # ok: ruby-job-injection-mailer-dynamic-action-deliver-later
    UserMailer.welcome(current_user).deliver_later
  end
end
