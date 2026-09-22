# Fixture for StringInterpolationInHtmlHref
# Tests both the vulnerable (BAD) and safe (GOOD) shapes.

module Banzai
  class ReferenceRedactor
    def redacted_node_content_bad(node)
      # BAD: percent-string with <a href> interpolating method-call results directly
      %(<a href="#{node.attr('href')}">#{node.attr('data-original')}</a>)
    end

    def redacted_node_content_bad2(node)
      # BAD: double-quoted string with <a href> and direct method-call interpolation
      "<a href=\"#{node.attr('data-original-href')}\">#{node.attr('data-original')}</a>"
    end

    def redacted_node_content_good(node)
      href    = node.attr('href')
      content = node.attr('data-original')

      # GOOD: uses DOM builder — no string interpolation into HTML structure
      a = node.document.create_element('a')
      a['href'] = href
      a.inner_html = content
      a.to_html
    end

    def static_link_good
      # GOOD: only a string literal in the interpolation — no dynamic data
      %(<a href="/users/list">#{"profile"}</a>)
    end
  end
end
