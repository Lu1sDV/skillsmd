# frozen_string_literal: true

# Simulated GraphQL type file under app/graphql/types/ for test fixtures.
# The query gates on file path matching %graphql/types/%.

module Types
  class CiVariableType < BaseObject
    # BAD: sensitive field (type name contains "Variable") with no authorize: — MUST flag
    field :ci_variables, CiVariableType, null: true,
      description: 'CI/CD variables for the project.'

    # GOOD: same sensitive field WITH authorize: — MUST NOT flag
    field :ci_variables, CiVariableType, null: true,
      authorize: :admin_pipeline,
      description: 'CI/CD variables (authorized).'

    # GOOD: non-sensitive field (field name :id, type GraphQL::Types::ID) with no authorize: — MUST NOT flag
    field :id, GraphQL::Types::ID, null: false,
      description: 'ID of the object.'

    # GOOD: non-sensitive field name and non-sensitive type with no authorize: — MUST NOT flag
    field :name, GraphQL::Types::String, null: true,
      description: 'Name of the resource.'

    # BAD: field name contains "token" (case-insensitive) with no authorize: — MUST flag
    field :access_token, TokenType, null: true,
      description: 'Access token for the resource.'

    # GOOD: field name contains "token" but HAS authorize: — MUST NOT flag
    field :access_token, TokenType, null: true,
      authorize: :read_token,
      description: 'Access token (authorized).'
  end
end
