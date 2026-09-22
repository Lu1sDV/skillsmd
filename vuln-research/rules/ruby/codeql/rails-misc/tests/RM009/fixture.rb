module Gitlab
  module Graphql
    class Variables
      MAX_JSON_SIZE_BYTES = 1_000_000

      Invalid = Class.new(StandardError)

      # BAD: private method recurses into itself without a depth counter or
      # MAX_RECURSION_DEPTH guard. An attacker can pass a deeply-nested JSON
      # string to cause stack overflow or memory exhaustion.
      def ensure_hash(ambiguous_param)
        case ambiguous_param
        when String
          if ambiguous_param.present?
            ensure_hash(parse_json(ambiguous_param))
          else
            {}
          end
        when Hash
          ambiguous_param
        when ActionController::Parameters
          ambiguous_param.to_unsafe_h
        else
          raise Invalid, "Expected a Hash, got #{ambiguous_param.class}"
        end
      end

      private :ensure_hash

      def parse_json(user_input)
        JSON.parse(user_input)
      rescue JSON::ParserError
        raise Invalid, "Invalid JSON"
      end
    end
  end
end

module Gitlab
  module Graphql
    class VariablesSafe
      MAX_RECURSION_DEPTH = 3

      Invalid = Class.new(StandardError)

      # GOOD: the method carries a `depth` parameter and checks it against
      # MAX_RECURSION_DEPTH before recursing — the fixed shape.
      def ensure_hash(ambiguous_param, depth = 0)
        case ambiguous_param
        when String
          if ambiguous_param.present?
            raise Invalid, "Parameters nested too deeply" if depth > MAX_RECURSION_DEPTH

            ensure_hash(parse_json(ambiguous_param), depth + 1)
          else
            {}
          end
        when Hash
          ambiguous_param
        when ActionController::Parameters
          ambiguous_param.to_unsafe_h
        else
          raise Invalid, "Expected a Hash, got #{ambiguous_param.class}"
        end
      end

      private :ensure_hash

      def parse_json(user_input)
        JSON.parse(user_input)
      rescue JSON::ParserError
        raise Invalid, "Invalid JSON"
      end
    end
  end
end
