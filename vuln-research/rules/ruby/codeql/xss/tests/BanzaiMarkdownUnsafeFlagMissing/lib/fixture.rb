# Fixture for BanzaiMarkdownUnsafeFlagMissing

module Banzai
  module Filter
    module MarkdownEngines
      class GlfmMarkdown
        # Constant options hash with unsafe: true — raw HTML always passes through.
        # BAD: unsafe: true is unconditional; user HTML is never stripped.
        OPTIONS = {
          sourcepos: true,
          header_ids: "user-content-",
          unsafe: true
        }.freeze

        def render_options
          OPTIONS
        end
      end

      class SafeRenderer
        # GOOD: unsafe is guarded by the raw_html_disabled? context flag.
        OPTIONS = {
          sourcepos: true,
          header_ids: "user-content-"
        }.freeze

        def render_options
          return OPTIONS unless raw_html_disabled?

          OPTIONS.merge(
            unsafe: !raw_html_disabled?
          )
        end

        private

        def raw_html_disabled?
          context[:disable_raw_html]
        end
      end
    end
  end
end
