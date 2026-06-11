# Fixture for Resque queue routing driven by request input.
# Flagged lines pick the destination queue from params; safe line names a fixed queue.

class ResqueRouteController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-resque-queue-instance-var-tainted
    Resque.enqueue_to(params[:queue], ReportJob, current_user.id)

    # ruleid: ruby-job-injection-resque-queue-instance-var-tainted
    Resque::Job.create(params[:queue], ReportJob, current_user.id)
  end

  def enqueue_safe
    # ok: ruby-job-injection-resque-queue-instance-var-tainted
    Resque.enqueue_to(:reports, ReportJob, current_user.id)
  end
end
