# BAD: FeatureSettingsResolver calls execute inside resolve with no Ability.allowed? guard
module Resolvers
  module Ai
    class FeatureSettingsResolver < BaseResolver
      def resolve(self_hosted_model_id: nil)
        feature_settings = ::Ai::FeatureSettings::FeatureSettingFinder.new(
          self_hosted_model_id: self_hosted_model_id
        ).execute
        feature_settings
      end
    end
  end
end

# BAD: UpdateMutation calls save! inside resolve with no raise_resource_not_available_error! guard
module Mutations
  class UpdateMutation < BaseMutation
    def resolve(**args)
      record = Model.find(args[:id])
      record.update!(args[:attributes])
      { record: record, errors: [] }
    end
  end
end

# GOOD: FeatureSettingsResolver with Ability.allowed? guard — must NOT be flagged
module Resolvers
  module Ai
    class GuardedFeatureSettingsResolver < BaseResolver
      def resolve(self_hosted_model_id: nil)
        return unless Ability.allowed?(current_user, :manage_instance_model_selection)

        feature_settings = ::Ai::FeatureSettings::FeatureSettingFinder.new(
          self_hosted_model_id: self_hosted_model_id
        ).execute
        feature_settings
      end
    end
  end
end

# GOOD: Mutation that raises via raise_resource_not_available_error! — must NOT be flagged
module Mutations
  class GuardedUpdateMutation < BaseMutation
    def resolve(**args)
      raise_resource_not_available_error! unless current_user&.admin?

      record = Model.find(args[:id])
      record.update!(args[:attributes])
      { record: record, errors: [] }
    end
  end
end
