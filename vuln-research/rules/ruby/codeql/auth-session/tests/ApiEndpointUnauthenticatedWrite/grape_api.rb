# Fixture for rb/auth-session-api-endpoint-unauthenticated-write (CWE-306)
# Mirrors the real GitLab fix in d19cd4411212 (MarkdownUploads < ::API::Base).

module API
  # BAD: Grape API class with POST/PUT/DELETE routes and no before { authenticate_non_get! }
  # All three non-GET routes must be flagged.
  class MarkdownUploads < Base
    params do
      requires :id, type: String
    end

    helpers do
      def find_uploads(parent)
        parent.uploads
      end
    end

    # BAD: POST route with no authentication hook
    post ':id/uploads/authorize' do
      require_gitlab_workhorse!
    end

    # BAD: POST route for actual upload — also unflagged
    post ':id/uploads' do
      upload_file(params[:file])
    end

    # BAD: DELETE route — also missing auth
    delete ':id/uploads/:secret/:filename' do
      destroy_upload
    end

    # GET is allowed without authentication (read-only) — should NOT be flagged
    get ':id/uploads' do
      present_uploads
    end
  end

  # GOOD: same class but with before { authenticate_non_get! } — no routes should flag
  class SafeMarkdownUploads < Base
    before { authenticate_non_get! }

    params do
      requires :id, type: String
    end

    post ':id/uploads/authorize' do
      require_gitlab_workhorse!
    end

    post ':id/uploads' do
      upload_file(params[:file])
    end

    delete ':id/uploads/:secret/:filename' do
      destroy_upload
    end

    get ':id/uploads' do
      present_uploads
    end
  end

  # GOOD: uses authenticate! instead of authenticate_non_get! — also acceptable
  class SafeWithAuthenticate < Base
    before { authenticate! }

    post ':id/things' do
      create_thing
    end
  end

  # NOT a Grape API class (different superclass) — should NOT flag
  class SomeController < ApplicationController
    def create
      render json: { ok: true }
    end
  end
end
