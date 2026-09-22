# frozen_string_literal: true

# BAD: controller processes an uploaded file via params[:manifest].tempfile
# but has no before_action that enforces a size limit.
class Import::ManifestControllerBad < Import::BaseController
  before_action :verify_import_enabled

  def upload
    manifest_file = params[:manifest].tempfile
    process(manifest_file)
  end

  private

  def process(file)
    # ... import logic
  end
end

# GOOD: controller has a before_action :check_file_size guard.
class Import::ManifestControllerGood < Import::BaseController
  MAX_MANIFEST_SIZE_IN_MB = 1

  before_action :verify_import_enabled
  before_action :check_file_size, only: [:upload]

  def upload
    manifest_file = params[:manifest].tempfile
    process(manifest_file)
  end

  private

  def check_file_size
    return if params[:manifest].tempfile.size <= MAX_MANIFEST_SIZE_IN_MB.megabytes

    render :new
  end

  def process(file)
    # ... import logic
  end
end
