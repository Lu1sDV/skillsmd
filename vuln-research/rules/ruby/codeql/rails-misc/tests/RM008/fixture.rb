# frozen_string_literal: true

# BAD: expose :value with no block in a CI variable entity — raw secret leaks
module Ci
  class BasicVariableEntity < Grape::Entity
    expose :id
    expose :key
    expose :value   # BAD: bare expose, no masking block
    expose :description
    expose :variable_type
  end
end

# BAD: another CI variable entity name variant
class ProjectVariableEntity < Grape::Entity
  expose :key
  expose :value   # BAD: bare expose, no masking block
  expose :masked
end

# GOOD: expose :value with a block that evaluates masking
module Ci
  class VariableEntity < Grape::Entity
    expose :id
    expose :key
    expose :value do |variable, _options|  # GOOD: block guards hidden/masked check
      if variable.respond_to?(:hidden)
        ::Ci::VariableValue.new(variable).evaluate
      else
        variable.value
      end
    end
  end
end

# GOOD: expose :value in a class that is NOT a variable entity — different domain
class DeployTokenEntity < Grape::Entity
  expose :value   # GOOD: not a variable entity, not in scope of this rule
end
