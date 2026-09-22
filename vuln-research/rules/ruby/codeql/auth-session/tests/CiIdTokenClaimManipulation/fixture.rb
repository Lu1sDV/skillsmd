# Fixture for CiIdTokenClaimManipulation
# Tests that project.full_path / project.id in JWT claims builders without a
# fork-origin guard are flagged, and that guarded variants are NOT flagged.

module Gitlab
  module Ci
    # BAD: custom_claims reads project.full_path without any source_project /
    #      merge_request_from_forked_project? guard — forked-MR tokens carry
    #      the target project's identity.
    class JwtV2Bad
      def custom_claims
        { project_path: project.full_path, # BAD: project.full_path in claims builder without fork guard
          ref_type: ref_type,
          ref: source_ref }
      end
    end

    # BAD: project_claims calls project.id without fork-origin check
    class JwtBad
      def project_claims
        ::JSONWebToken::ProjectTokenClaims
          .new(project: project.id, user: user) # BAD: project.id in claims builder without fork guard
          .generate
      end
    end

    # GOOD: custom_claims uses source_project (the fork-aware accessor)
    class JwtV2Good
      def source_project
        pipeline.merge_request_from_forked_project? ? pipeline.merge_request.source_project : project
      end

      def custom_claims
        { project_path: source_project.full_path, # GOOD: source_project used — fork origin respected
          ref_type: ref_type,
          ref: source_ref }
      end
    end

    # GOOD: project_claims explicitly checks merge_request_from_forked_project?
    class JwtGood
      def project_claims
        src = merge_request_from_forked_project? ? merge_request.source_project : project
        ::JSONWebToken::ProjectTokenClaims
          .new(project: src, user: user) # GOOD: fork check present in same callable
          .generate
      end
    end
  end
end
