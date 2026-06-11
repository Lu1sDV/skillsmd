# Fixture for dynamic Que class dispatch.
# Flagged lines derive the job class from params; safe line uses a fixed class.

class QueController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-que-dynamic-class
    Que.enqueue(params[:task].constantize, current_user.id)

    # ruleid: ruby-job-injection-que-dynamic-class
    Que.enqueue(job_class: params[:task], args: [1])
  end

  def enqueue_safe
    # ok: ruby-job-injection-que-dynamic-class
    Que.enqueue(BillingJob, current_user.id)
  end
end
