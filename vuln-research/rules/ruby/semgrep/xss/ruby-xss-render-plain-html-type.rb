# Fixture covering render plain forced to text/html.

def note
  # ruleid: ruby-xss-render-plain-html-type
  render plain: params[:note], content_type: "text/html"
end

def note_plain
  # ok: ruby-xss-render-plain-html-type
  render plain: params[:note]
end
