# Fixture for BanzaiSanitizeFragmentAsNodeContent

module Banzai
  module Filter
    class ImageLinkFilter
      # BAD: Sanitize.fragment called on an HTML attribute value (ElementReference).
      # img['alt'] is an attribute value that may contain markup; Sanitize.fragment
      # does not guarantee a safe plain-text result — it can pass HTML through.
      def link_children(img)
        [img['alt'], img['data-src'], img['src']]
          .map { |f| Sanitize.fragment(f).presence }.compact.first || ''
      end

      # GOOD: attribute values are used directly as plain text; no Sanitize.fragment.
      # node.content= auto-escapes HTML, so markup in the attribute value is inert.
      def link_text(img)
        [img['alt'], img['data-src'], img['src']].filter_map(&:presence).first || ''
      end

      def call
        doc.search('img').each do |img|
          link = doc.document.create_element('a')
          # BAD: children= assignment driven by Sanitize.fragment on attribute values.
          link.children = link_children(img)

          # GOOD: content= assignment uses plain-text value; no Sanitize.fragment.
          link.content = link_text(img)

          img.replace(link)
        end
      end
    end
  end
end
