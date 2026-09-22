# frozen_string_literal: true

module Banzai
  module Filter
    # BAD: CGI.escapeHTML called directly on a proc's return value.
    # HTML tags in the replacement survive because escapeHTML encodes
    # '&', '<', '>' but does NOT strip <script> or other tags before encoding.
    # An attacker whose data reaches `action` can inject HTML into the output.
    class PlaceholderPostFilterBad
      def replace_placeholder_action(action)
        CGI.escapeHTML(action.call(context) || '') # BAD: no tag-stripping before escapeHTML
      end

      private

      def context
        {}
      end
    end

    # GOOD: tags are stripped via a sanitization filter first;
    # only plain text is then HTML-entity-encoded.
    class PlaceholderPostFilterGood
      def replace_placeholder_action(action)
        replacement = action.call(context) || ''
        node = SanitizationFilter.new(replacement).call
        CGI.escapeHTML(node.text)           # GOOD: sanitized first, then escaped
      end

      private

      def context
        {}
      end
    end
  end
end
