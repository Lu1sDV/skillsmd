# Fixture for the raw Mail.new build detector.

class IngestController < ApplicationController
  def import
    # ruleid: ruby-mail-header-injection-mail-new-raw
    msg = Mail.new(params[:raw])
    deliver(msg)
  end

  def import_string
    # ruleid: ruby-mail-header-injection-mail-new-raw
    msg = Mail.read_from_string(params[:raw])
    deliver(msg)
  end

  def import_safe
    # ok: ruby-mail-header-injection-mail-new-raw
    msg = Mail.new(to: current_user.email, subject: "Welcome")
    deliver(msg)
  end
end
