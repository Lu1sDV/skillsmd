# Fixture for the interpolated subject header detector.

class TicketMailer < ApplicationMailer
  def created
    # ruleid: ruby-mail-header-injection-mail-subject-interp
    mail(to: agent.email, subject: "Ticket #{params[:title]}")
  end

  def created_safe
    # ok: ruby-mail-header-injection-mail-subject-interp
    mail(to: agent.email, subject: t(".ticket_created"))
  end
end
