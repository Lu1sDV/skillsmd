module Gitlab
  module Asciidoc
    COMPLEX_MARKDOWN_MESSAGE = "content too complex to render".freeze

    # BAD: html_safe is called inside the same block as Asciidoctor.convert().
    # If a Timeout::Error escapes the Banzai.render() call, the raw unsanitized
    # Asciidoctor HTML is returned html_safe. The receiver of html_safe is NOT
    # a Banzai.render() call — it is a local variable holding convert() output.
    def self.render_bad(input, context)
      Gitlab::RenderTimeout.timeout(foreground: 30) do
        html = ::Asciidoctor.convert(input, {})
        html = Banzai.render(html, context)
        html.html_safe  # BAD: html_safe inside the block alongside convert()
      end
    rescue Timeout::Error
      input  # BAD: returns raw input on timeout, not a safe constant
    end

    # GOOD: Asciidoctor.convert() is called in isolation; html_safe is applied
    # to the result of Banzai.render() after sanitization, outside the convert block.
    def self.render_good(input, context)
      html = begin
        Gitlab::RenderTimeout.timeout(foreground: 30) { ::Asciidoctor.convert(input, {}) }
      rescue Timeout::Error
        COMPLEX_MARKDOWN_MESSAGE  # GOOD: safe constant on error path
      end

      Banzai.render(html, context).html_safe  # GOOD: html_safe on Banzai.render() result
    end
  end
end
