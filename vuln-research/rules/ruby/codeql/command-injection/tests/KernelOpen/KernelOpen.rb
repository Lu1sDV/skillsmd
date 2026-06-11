class FilesController < ActionController::Base
  def show
    path = params[:path]
    # true positive: user input into Kernel#open, a leading "|" runs a command
    contents = open(path).read
    render plain: contents
  end

  def safe
    # negative: File.open never spawns a process even on a "|"-prefixed name
    File.open(params[:path]).read
  end
end
