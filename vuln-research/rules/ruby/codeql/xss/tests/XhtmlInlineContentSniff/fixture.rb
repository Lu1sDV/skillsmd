# Fixtures for XhtmlInlineContentSniff

require 'action_dispatch'

# ---------------------------------------------------------------------------
# BAD cases — ContentDisposition.format with disposition:'inline' and a
# non-nil filename.  These must be flagged.
# ---------------------------------------------------------------------------

class WorkhorseHelper
  def content_disposition_for_blob(blob)
    # BAD: filename comes directly from blob.name; no .xhtml guard
    ActionDispatch::Http::ContentDisposition.format(disposition: 'inline', filename: blob.name) # $ Alert
  end

  def send_snippet_raw(blob)
    # BAD: local variable, still no strip applied
    fname = blob.name
    ContentDisposition.format(disposition: 'inline', filename: fname) # $ Alert
  end
end

# ---------------------------------------------------------------------------
# GOOD cases — either filename is nil (extension stripped) or disposition is
# not 'inline'.  These must NOT be flagged.
# ---------------------------------------------------------------------------

class WorkhorseHelperFixed
  def inline_content_disposition_nil(blob)
    # GOOD: filename is the nil literal — extension stripped upstream; safe
    ActionDispatch::Http::ContentDisposition.format(disposition: 'inline', filename: nil)
  end

  def attachment_content_disposition(blob)
    # GOOD: disposition is 'attachment', not 'inline' — no content-sniffing risk
    ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename: blob.name)
  end

  def inline_no_filename(blob)
    # GOOD: no filename: keyword argument at all — query only fires when filename: is present
    ContentDisposition.format(disposition: 'inline')
  end
end
