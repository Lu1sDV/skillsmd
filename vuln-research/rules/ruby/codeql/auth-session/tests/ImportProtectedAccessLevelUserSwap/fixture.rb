module Gitlab
  module ImportExport
    module Project
      # BAD: RelationFactory that instantiates ProtectedBranch::MergeAccessLevel
      # with user_id from import data, but has no admin/owner guard.
      class RelationFactory
        def build_access_level(relation_hash)
          # BAD: user_id accepted from attacker-controlled import data with no privilege check
          ProtectedBranch::MergeAccessLevel.new(user_id: relation_hash['user_id'],
                                                access_level: relation_hash['access_level'])
        end

        def build_push_access_level(relation_hash)
          # BAD: same pattern for push access level
          ProtectedBranch::PushAccessLevel.new(user_id: relation_hash['user_id'],
                                               access_level: relation_hash['access_level'])
        end

        def build_unprotect_access_level(relation_hash)
          # BAD: same pattern for unprotect access level
          ProtectedBranch::UnprotectAccessLevel.new(
            user_id: relation_hash['user_id']
          )
        end

        def build_tag_access_level(relation_hash)
          # BAD: ProtectedTag::CreateAccessLevel also carries user_id
          ProtectedTag::CreateAccessLevel.new(user_id: relation_hash['user_id'])
        end
      end

      # GOOD: Same factory but guarded by an admin/owner check before accepting user_id.
      class SafeRelationFactory
        def build_access_level(relation_hash)
          # GOOD: guarded — only create with user_id when caller has admin rights
          return unless user_can_admin_importable?

          ProtectedBranch::MergeAccessLevel.new(user_id: relation_hash['user_id'],
                                                access_level: relation_hash['access_level'])
        end

        def build_push_access_level(relation_hash)
          # GOOD: can_admin_all_resources? guard present
          return unless user.can_admin_all_resources?

          ProtectedBranch::PushAccessLevel.new(user_id: relation_hash['user_id'],
                                               access_level: relation_hash['access_level'])
        end

        def build_tag_access_level(relation_hash)
          # GOOD: can?(:owner_access, importable) guard present
          return unless user.can?(:owner_access, importable)

          ProtectedTag::CreateAccessLevel.new(user_id: relation_hash['user_id'])
        end

        private

        def user_can_admin_importable?
          user.can_admin_all_resources? || user.can?(:owner_access, importable)
        end
      end
    end
  end
end
