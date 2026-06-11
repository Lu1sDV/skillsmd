# Fixture for ActiveJob scheduling time taken from request input.
# Flagged lines schedule from params; safe line computes the time server-side.

class ScheduleJobController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-activejob-set-wait-until-tainted
    DigestJob.set(wait_until: Time.parse(params[:at])).perform_later(current_user.id)

    # ruleid: ruby-job-injection-activejob-set-wait-until-tainted
    DigestJob.set(wait: params[:delay]).perform_later(current_user.id)
  end

  def enqueue_safe
    # ok: ruby-job-injection-activejob-set-wait-until-tainted
    DigestJob.set(wait_until: 1.day.from_now).perform_later(current_user.id)
  end
end
