# Fixture covering the Rails raw helper sink.

def show_comment
  # ruleid: ruby-xss-raw-helper
  raw(params[:comment])
end

def banner(user)
  # ruleid: ruby-xss-raw-helper
  raw("<b>#{user.bio}</b>")
end

def fetched
  # ruleid: ruby-xss-raw-helper
  raw(params.fetch(:body))
end

def static_markup
  # ok: ruby-xss-raw-helper
  raw("<hr>")
end
