class Widget
  # True positive: a gem-public method interpolates its caller-supplied argument
  # into an HTML fragment and marks it html_safe, so a caller passing attacker
  # data produces an XSS payload. `name` is a library input source; the string
  # interpolation is the unsafe-construction sink whose result reaches html_safe.
  def heading(name)
    "<h2>#{name}</h2>".html_safe
  end

  # Safe: the argument is HTML-escaped before interpolation, so the constructed
  # fragment cannot carry markup.
  def safe_heading(name)
    "<h2>#{ERB::Util.html_escape(name)}</h2>".html_safe
  end
end
