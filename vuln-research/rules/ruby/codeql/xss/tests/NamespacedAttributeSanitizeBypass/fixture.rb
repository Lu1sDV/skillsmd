# frozen_string_literal: true

# Minimal stub classes so the fixture parses without Rails/Banzai dependencies.
module Sanitize; end

module Banzai
  module Filter
    # BAD: transformer reads env[:node].attributes (local-name hash only) without
    # ever calling attribute_nodes. A namespaced attribute such as xlink:href is
    # invisible to this accessor and its dangerous value survives sanitisation.
    class UnsafeLinkFilter
      def self.strip_javascript_hrefs(env)
        node = env[:node]
        node.attributes.each do |name, attr| # BAD: .attributes without .attribute_nodes
          attr.remove if name == 'href' && attr.value.start_with?('javascript:')
        end
      end
    end

    # GOOD: transformer calls attribute_nodes in the same method, so namespaced
    # attributes (e.g. xlink:href) are also handled and no bypass is possible.
    class SafeLinkFilter
      def self.strip_namespaced_and_javascript(env)
        node = env[:node]
        # Remove ALL namespaced attributes first (fixes the bypass).
        node.attribute_nodes.each do |attr|
          attr.remove if attr.namespace
        end
        # Then handle the plain un-namespaced href.
        node.attributes.each do |name, attr|
          attr.remove if name == 'href' && attr.value.start_with?('javascript:')
        end
      end
    end
  end
end
