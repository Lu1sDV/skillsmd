require 'cgi'

module Banzai
  module Filter
    module References
      # BAD: object_link_text returns plain text with no CGI.escapeHTML call.
      # The framework inserts this return value verbatim into an <a> tag body,
      # so any HTML special characters (e.g. from object.title) cause XSS.
      class VulnerableReferenceFilter
        def object_link_text(object, matches)
          # BAD: plain string returned; no CGI.escapeHTML wrapping
          extras = object_link_text_extras(object, matches)
          text = object.reference_link_text(nil)
          text += " (#{extras.join(', ')})" if extras.any?
          text
        end

        def object_link_text_extras(object, matches)
          []
        end
      end

      # BAD: a minimal override that just delegates to super with escape_once —
      # escape_once is not CGI.escapeHTML and the framework still treats the
      # return value as plain text before inserting it into HTML.
      class AnotherVulnerableFilter
        def object_link_text(object, matches)
          # BAD: escape_once is not CGI.escapeHTML
          escape_once(super)
        end
      end

      # GOOD: the method has been renamed to object_link_content_html and wraps
      # the text with CGI.escapeHTML before returning — this is the fixed shape.
      class FixedReferenceFilter
        def object_link_content_html(object, matches)
          parent = project || group || user
          html = CGI.escapeHTML(object.reference_link_text(parent))
          extras = object_link_content_html_extras(object, matches)
          html += " (#{extras.join(', ')})" if extras.any?
          html
        end

        def object_link_content_html_extras(object, matches)
          []
        end
      end

      # GOOD: still named object_link_text but DOES call CGI.escapeHTML internally —
      # query must not flag this variant.
      class EscapedObjectLinkText
        def object_link_text(object, matches)
          # GOOD: uses CGI.escapeHTML so the return value is safe
          CGI.escapeHTML(object.reference_link_text(nil))
        end
      end
    end
  end
end
