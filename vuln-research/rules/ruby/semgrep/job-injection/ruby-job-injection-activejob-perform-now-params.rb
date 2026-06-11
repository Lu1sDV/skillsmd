# Fixture for running an ActiveJob inline with raw params.
# Flagged lines pass request params into perform_now; safe line passes a scalar id.

class InlineController < ApplicationController
  def run
    # ruleid: ruby-job-injection-activejob-perform-now-params
    ImportJob.perform_now(params)

    # ruleid: ruby-job-injection-activejob-perform-now-params
    ImportJob.perform_now(params.to_h, current_user.id)
  end

  def run_safe
    # ok: ruby-job-injection-activejob-perform-now-params
    ImportJob.perform_now(current_user.id)
  end
end
