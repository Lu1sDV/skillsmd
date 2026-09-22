# Fixture for DataHtmlTooltipSink (RB-QL-0808)
# BAD: dataset.merge! with html: true enables tooltip lib to render title as raw HTML
# GOOD: assign title directly without html: true flag

module LabelsHelper
  # BAD: html: true in merge! — XSS if title is user-controlled
  def render_label_link_bad(label_html, link:, title:, dataset:)
    if title.present?
      dataset.merge!(html: true, title: title) # BAD: html: true enables raw HTML in tooltip
    end
    link_to(label_html, link, data: dataset)
  end

  # GOOD: title assigned directly — tooltip library HTML-escapes the value
  def render_label_link_good(label_html, link:, title:, dataset:)
    if title.present?
      dataset['title'] = title # GOOD: no html: true, title is HTML-escaped
    end
    link_to(label_html, link, data: dataset)
  end
end
