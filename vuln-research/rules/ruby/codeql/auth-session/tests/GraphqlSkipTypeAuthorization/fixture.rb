# frozen_string_literal: true

# Fixture for GraphqlSkipTypeAuthorization
# Tests that skip_type_authorization: with a non-empty array is flagged,
# and that the fixed form (keyword removed) is not flagged.

module Types
  class WorkItemType < BaseObject
    # BAD: skip_type_authorization with a non-empty scope list bypasses type-level authz
    field :project, Types::ProjectType, null: true,
      description: 'Project the work item belongs to.',
      skip_type_authorization: [:read_project]

    # BAD: different scope symbol — still non-empty, still flagged
    field :namespace, Types::NamespaceType, null: true,
      description: 'Namespace the work item belongs to.',
      skip_type_authorization: [:read_namespace]

    # GOOD: skip_type_authorization keyword removed entirely — type-level authz active
    field :author, Types::UserType, null: true,
      description: 'Author of the work item.'

    # GOOD: empty array — getNumberOfElements() == 0, not flagged
    field :milestone, Types::MilestoneType, null: true,
      description: 'Milestone of the work item.',
      skip_type_authorization: []
  end
end
