# Fixture: partially-migrated Grape API class (lib/api/ path simulated)
# One endpoint already has route_setting :authorization (GOOD — should NOT flag)
# One endpoint is missing it (BAD — MUST flag)
# A second class with NO route_setting at all is also NOT flagged (fully unmigrated).

module API
  class Pipelines < ::API::Base
    resource :projects do
      params do
        requires :id, type: String
      end

      # GOOD: route_setting :authorization present immediately before the verb
      route_setting :authorization, permissions: :read_pipeline, boundary_type: :project
      get ':id/pipelines' do
        authorize! :read_pipeline, user_project
      end

      # BAD: missing route_setting :authorization before this endpoint
      post ':id/pipelines' do
        authorize! :create_pipeline, user_project
      end

      # GOOD: route_setting :authorization present immediately before this verb too
      route_setting :authorization, permissions: :delete_pipeline, boundary_type: :project
      delete ':id/pipelines/:pipeline_id' do
        authorize! :destroy_pipeline, pipeline
      end
    end
  end

  # Fully unmigrated class — no route_setting :authorization anywhere.
  # Should NOT flag (FP mitigation: only flag partially-migrated classes).
  class Jobs < ::API::Base
    resource :projects do
      get ':id/jobs' do
        authorize! :read_build, user_project
      end

      post ':id/jobs' do
        authorize! :create_build, user_project
      end
    end
  end
end
