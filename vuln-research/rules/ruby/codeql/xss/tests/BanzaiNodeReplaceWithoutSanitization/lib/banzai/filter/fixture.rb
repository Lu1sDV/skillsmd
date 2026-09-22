# Fixture for BanzaiNodeReplaceWithoutSanitization
# This file lives under lib/banzai/filter/ in production; the test harness
# resolves relative paths from the test directory so the path predicate fires.

module Banzai
  module Filter
    # BAD: node.replace(html) called with user-derived html, no SanitizationFilter
    class GollumTagsFilter
      def call
        doc.search('text()').each do |node|
          next unless node.content =~ /\[\[(.+?)\]\]/

          html = process_tag(Regexp.last_match(1))

          # BAD: html comes from user wiki tag content, no sanitization applied
          node.replace(html) if html && html != node.content
        end

        doc
      end

      private

      def process_tag(tag)
        "<a href='/wiki/#{tag}'>#{tag}</a>"
      end
    end

    # GOOD: node.replace() called only after SanitizationFilter sanitizes the HTML
    class GollumTagsFilterSafe
      def call
        doc.search('text()').each do |node|
          next unless node.content =~ /\[\[(.+?)\]\]/

          html = process_tag(Regexp.last_match(1))
          next unless html && html != node.content

          # GOOD: HTML is passed through SanitizationFilter before replacing
          new_node = Banzai::Filter::SanitizationFilter.new(html).call
          new_node = new_node&.children&.first&.add_class('gfm')
          node.replace(new_node.to_html) if new_node
        end

        doc
      end

      private

      def process_tag(tag)
        "<a href='/wiki/#{tag}'>#{tag}</a>"
      end
    end
  end
end
