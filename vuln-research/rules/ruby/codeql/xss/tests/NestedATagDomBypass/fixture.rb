# Fixture for NestedATagDomBypass
# Tests that a Banzai sanitization filter pushing transformers without
# registering method(:unwrap_nested_a) is flagged, and one that does
# register it is not flagged.

module Banzai
  module Filter
    # BAD: allowlist method pushes a transformer but never registers
    # method(:unwrap_nested_a), so nested <a> tags survive sanitization
    # and can leak redacted reference text via data-original.
    class VulnerableSanitizationFilter
      def allowlist
        allowlist = super

        allowlist[:protocols].delete('a')

        # BAD: push transformer without the nested-a unwrap guard
        allowlist[:transformers].push(self.class.method(:remove_rel))

        allowlist
      end

      class << self
        def remove_rel(env)
          return unless env[:node_name] == 'a'
          env[:node].remove_attribute('rel')
        end
      end
    end

    # GOOD: allowlist method also pushes method(:unwrap_nested_a), so
    # nested <a> tags are removed before later pipeline stages run.
    class FixedSanitizationFilter
      def allowlist
        allowlist = super

        allowlist[:protocols].delete('a')

        allowlist[:transformers].push(self.class.method(:remove_rel))

        # GOOD: nested-a guard is registered
        allowlist[:transformers].push(self.class.method(:unwrap_nested_a))

        allowlist
      end

      class << self
        def remove_rel(env)
          return unless env[:node_name] == 'a'
          env[:node].remove_attribute('rel')
        end

        def unwrap_nested_a(env)
          node = env[:node]
          return unless node.element? && node.name == 'a'
          return unless node.ancestors.any? { |ancestor| ancestor.element? && ancestor.name == 'a' }

          node.replace(node.children)
        end
      end
    end
  end
end
