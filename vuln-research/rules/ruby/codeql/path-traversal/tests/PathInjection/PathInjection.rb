class DownloadsController < ActionController::Base
  def show
    name = params[:file]
    # true positive: tainted parameter used as a filesystem path argument
    File.read("/var/data/#{name}")
  end

  def safe
    # negative: constant path, no taint
    File.read("/var/data/readme.txt")
  end
end
