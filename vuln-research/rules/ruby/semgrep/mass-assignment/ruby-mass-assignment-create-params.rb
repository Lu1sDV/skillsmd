# Fixture for the create-params rule.

def make_post
  # ruleid: ruby-mass-assignment-create-params
  Post.create(params[:post])
end

def make_comment
  # ruleid: ruby-mass-assignment-create-params
  Comment.create(params[:comment], author: current_user)
end

def make_post_safe
  # ok: ruby-mass-assignment-create-params
  Post.create(params.require(:post).permit(:title, :body))
end

def make_from_literal
  # ok: ruby-mass-assignment-create-params
  Post.create(title: "hello")
end
