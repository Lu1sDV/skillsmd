# Fixture for Delayed Job scheduling a method named by request input.
# Flagged lines send a params method through the delay proxy; safe line names the method.

class DelayDispatchController < ApplicationController
  def schedule
    # ruleid: ruby-job-injection-delayed-job-dynamic-method
    account.delay.public_send(params[:op], current_user.id)

    # ruleid: ruby-job-injection-delayed-job-dynamic-method
    account.delay(run_at: 1.hour.from_now).public_send(params[:op])
  end

  def schedule_safe
    # ok: ruby-job-injection-delayed-job-dynamic-method
    account.delay.recalculate_balance(current_user.id)
  end
end
