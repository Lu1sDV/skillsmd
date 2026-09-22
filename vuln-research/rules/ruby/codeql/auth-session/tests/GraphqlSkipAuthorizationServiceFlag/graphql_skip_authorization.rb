# Test fixtures for rb/auth-session-graphql-skip-authorization-service-flag (CWE-285).

module Mutations
  module BranchRules
    module ApprovalProjectRules
      # BAD: resolve merges skip_authorization: true into service params,
      #      disabling the service's can? guard.
      class Create < BaseMutation
        def resolve(branch_rule_id:, **params)
          create_params = params.merge(
            skip_authorization: true,
            applies_to_all_protected_branches: false
          )
          result = CreateService.new(current_user, project, create_params).execute
          { errors: result.errors }
        end
      end

      # GOOD: same mutation but skip_authorization: true has been removed.
      class CreateFixed < BaseMutation
        def resolve(branch_rule_id:, **params)
          create_params = params.merge(
            applies_to_all_protected_branches: false
          )
          result = CreateService.new(current_user, project, create_params).execute
          { errors: result.errors }
        end
      end

      # GOOD: merge! without skip_authorization key — unrelated merge.
      class Update < BaseMutation
        def resolve(**params)
          update_params = params.merge!(protected_branch_ids: [1, 2])
          result = UpdateService.new(current_user, project, update_params).execute
          { errors: result.errors }
        end
      end

      # GOOD: skip_authorization: false — not bypassing the guard.
      class CreateWithFalse < BaseMutation
        def resolve(**params)
          safe_params = params.merge(skip_authorization: false)
          result = CreateService.new(current_user, project, safe_params).execute
          { errors: result.errors }
        end
      end
    end
  end
end
