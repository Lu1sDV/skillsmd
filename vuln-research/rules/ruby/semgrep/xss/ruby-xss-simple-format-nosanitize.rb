# Fixture covering simple_format with sanitization disabled.

def bio(text)
  # ruleid: ruby-xss-simple-format-nosanitize
  simple_format(text, {}, sanitize: false)
end

def safe_bio(text)
  # ok: ruby-xss-simple-format-nosanitize
  simple_format(text)
end
