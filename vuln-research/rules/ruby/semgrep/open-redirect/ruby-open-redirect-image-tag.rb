# Fixture for image_tag with a tainted source.

module AvatarHelper
  def avatar
    # ruleid: ruby-open-redirect-image-tag
    image_tag(params[:avatar_url])
  end

  def avatar_interp(user)
    # ruleid: ruby-open-redirect-image-tag
    image_tag("https://#{user.gravatar_host}/a.png")
  end

  def safe_avatar
    # ok: ruby-open-redirect-image-tag
    image_tag("default-avatar.png")
  end
end
