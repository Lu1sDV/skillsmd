# Fixture for MarkdownFieldRawApiExposure

module API
  module Entities
    # BAD: expose :description_html bare — cached raw HTML returned without
    #      user-context sanitization, cross-user reference leakage possible.
    class LabelBad < Grape::Entity
      expose :id, :name, :description

      # BAD: bare expose of a *_html field — no MarkupHelper.markdown_field block
      expose :description_html
    end

    # GOOD: expose :description_html with a MarkupHelper.markdown_field block
    class LabelGood < Grape::Entity
      expose :id, :name, :description

      # GOOD: re-renders through MarkupHelper so user-context redaction applies
      expose :description_html do |label, options|
        MarkupHelper.markdown_field(label, :description, current_user: options[:current_user])
      end
    end

    # GOOD: field name does not end in _html — not flagged
    class ProjectSafe < Grape::Entity
      expose :readme_content
      expose :avatar_url
    end
  end
end
