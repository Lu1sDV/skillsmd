# Fixture for dynamic Resque class dispatch.
# Flagged lines constantize a params value as the job class; safe line uses a constant.

class ResqueController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-resque-enqueue-dynamic-class
    Resque.enqueue(params[:job].constantize, current_user.id)

    # ruleid: ruby-job-injection-resque-enqueue-dynamic-class
    Resque.enqueue_to("high", params[:job].constantize, current_user.id)
  end

  def enqueue_safe
    # ok: ruby-job-injection-resque-enqueue-dynamic-class
    Resque.enqueue(ImageResizeJob, current_user.id)
  end
end
