# Fixture covering Haml preserve helpers wrapping raw content.

def block(text)
  # ruleid: ruby-xss-haml-preserve-raw
  preserve(raw(text))
end

def block_fp(text)
  # ruleid: ruby-xss-haml-preserve-raw
  find_and_preserve(raw(text))
end

def block_safe(text)
  # ok: ruby-xss-haml-preserve-raw
  preserve(text)
end
