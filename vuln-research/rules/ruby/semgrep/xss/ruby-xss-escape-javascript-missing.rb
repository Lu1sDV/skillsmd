# Fixture covering interpolation into a script block without js escaping.

def inline_config(token)
  # ruleid: ruby-xss-escape-javascript-missing
  raw("<script>var t = '#{token}'</script>")
end

def inline_safe(token)
  # ruleid: ruby-xss-escape-javascript-missing
  "<script>var t = '#{token}'</script>".html_safe
end

def escaped_config(token)
  # ok: ruby-xss-escape-javascript-missing
  content_tag(:script, "var t = #{token.to_json}")
end
