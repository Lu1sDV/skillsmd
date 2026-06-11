# Fixture for scheduled Sidekiq jobs driven by request input.
# Flagged lines take the delay or args from params; safe line uses a fixed interval and id.

class ScheduleController < ApplicationController
  def schedule
    # ruleid: ruby-job-injection-sidekiq-job-perform-in-params
    ReminderWorker.perform_in(params[:delay], current_user.id)

    # ruleid: ruby-job-injection-sidekiq-job-perform-in-params
    ReminderWorker.perform_in(10.minutes, params)
  end

  def schedule_safe
    # ok: ruby-job-injection-sidekiq-job-perform-in-params
    ReminderWorker.perform_in(10.minutes, current_user.id)
  end
end
