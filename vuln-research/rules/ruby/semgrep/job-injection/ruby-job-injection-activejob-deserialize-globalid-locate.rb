# Fixture for resolving an attacker-supplied GlobalID before enqueueing work.
# Flagged lines locate a record straight from params; safe line scopes to the current user.

class GidController < ApplicationController
  def enqueue
    # ruleid: ruby-job-injection-activejob-deserialize-globalid-locate
    record = GlobalID::Locator.locate(params[:gid])

    # ruleid: ruby-job-injection-activejob-deserialize-globalid-locate
    records = GlobalID::Locator.locate_many(params[:gids])

    ProcessJob.perform_later(record, records)
  end

  def enqueue_safe
    # ok: ruby-job-injection-activejob-deserialize-globalid-locate
    record = current_user.documents.find(params[:id])
    ProcessJob.perform_later(record)
  end
end
