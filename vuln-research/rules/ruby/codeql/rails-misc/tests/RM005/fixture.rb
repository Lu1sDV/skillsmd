module API
  module Entities
    # BAD: expose :pipeline without Ability.allowed? in the if: lambda
    class PackageWithPipeline < Grape::Entity
      expose :id
      expose :name

      # BAD: presence-only guard on :pipeline — no permission check
      expose :pipeline, if: ->(package) { package.last_build_info }, using: Package::Pipeline

      # BAD: presence-only guard on :pipelines — no permission check
      expose :pipelines, if: ->(package) { package.pipelines.present? }, using: Package::Pipeline
    end

    # BAD: expose :trace without permission check
    class JobEntity < Grape::Entity
      expose :id
      expose :name

      # BAD: checks data presence but not read permission
      expose :trace, if: ->(job) { job.trace.present? }
    end

    # BAD: expose :token without permission check
    class TokenEntity < Grape::Entity
      expose :token, if: ->(obj) { obj.token.present? }
    end

    # GOOD: expose :pipeline with Ability.allowed? guard — should NOT flag
    class PackageWithPermission < Grape::Entity
      expose :pipeline, if: ->(package, opts) {
        package.last_build_info && Ability.allowed?(opts[:user], :read_pipeline, package.project)
      }, using: Package::Pipeline

      expose :pipelines, if: ->(package, opts) {
        package.pipelines.present? && Ability.allowed?(opts[:user], :read_pipeline, package.project)
      }, using: Package::Pipeline
    end

    # GOOD: expose :trace with can? guard — should NOT flag
    class JobEntityFixed < Grape::Entity
      expose :trace, if: ->(job, opts) {
        job.trace.present? && can?(opts[:user], :read_build, job.project)
      }
    end

    # GOOD: non-sensitive field with presence-only guard — should NOT flag
    class SafeEntity < Grape::Entity
      expose :description, if: ->(obj) { obj.description.present? }
      expose :created_at
    end
  end
end
