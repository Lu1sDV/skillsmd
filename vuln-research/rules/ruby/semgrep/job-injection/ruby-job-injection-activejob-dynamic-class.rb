# Fixture for dynamic ActiveJob class dispatch.
# Flagged lines resolve the worker class from request data; safe line uses a fixed class.

class JobsController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-activejob-dynamic-class
    params[:job_class].constantize.perform_later(current_user.id)

    # ruleid: ruby-job-injection-activejob-dynamic-class
    params[:worker].safe_constantize.perform_later(record_id)
  end

  def enqueue_safe
    # ok: ruby-job-injection-activejob-dynamic-class
    ReportExportJob.perform_later(current_user.id)
  end
end
