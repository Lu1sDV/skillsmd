# Fixture for the update-all-params rule.

def bulk_overwrite
  # ruleid: ruby-mass-assignment-update-all-params
  Post.where(author_id: current_user.id).update_all(params[:post])
end

def bulk_overwrite_unsafe
  # ruleid: ruby-mass-assignment-update-all-params
  Post.all.update_all(params.to_unsafe_h)
end

def bulk_overwrite_safe
  # ok: ruby-mass-assignment-update-all-params
  Post.where(author_id: current_user.id).update_all(archived: true)
end
