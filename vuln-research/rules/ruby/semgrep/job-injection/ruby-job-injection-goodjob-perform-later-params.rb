# Fixture for raw params passed into a GoodJob ActiveJob.
# Flagged lines enqueue request params; safe line enqueues a scalar id.

class GoodJobController < ApplicationController
  def create
    # ruleid: ruby-job-injection-goodjob-perform-later-params
    SyncJob.perform_later(params)

    # ruleid: ruby-job-injection-goodjob-perform-later-params
    SyncJob.perform_later(params.permit!, current_user.id)
  end

  def create_safe
    # ok: ruby-job-injection-goodjob-perform-later-params
    SyncJob.perform_later(current_user.id)
  end
end
