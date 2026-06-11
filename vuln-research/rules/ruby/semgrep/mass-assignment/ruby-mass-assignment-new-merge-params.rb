# Fixture for the new-merge-params rule.

def build_with_defaults
  # ruleid: ruby-mass-assignment-new-merge-params
  Post.new({ status: "draft" }.merge(params[:post]))
end

def create_with_defaults(defaults)
  # ruleid: ruby-mass-assignment-new-merge-params
  Comment.create(defaults.merge(params[:comment]))
end

def build_with_defaults_safe
  # ok: ruby-mass-assignment-new-merge-params
  Post.new({ status: "draft" }.merge(params.require(:post).permit(:title)))
end
