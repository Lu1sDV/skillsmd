# Fixture covering image_tag with attacker-controlled src.

def avatar
  # ruleid: ruby-xss-image-tag-src
  image_tag(params[:avatar_url])
end

def avatar_alt
  # ruleid: ruby-xss-image-tag-src
  image_tag(params[:avatar_url], alt: "Avatar")
end

def logo
  # ok: ruby-xss-image-tag-src
  image_tag("logo.png")
end
