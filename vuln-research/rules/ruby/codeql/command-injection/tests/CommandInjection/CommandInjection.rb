class JobsController < ActionController::Base
  def run
    name = params[:name]
    # true positive: tainted parameter interpolated into a shell command
    system("echo #{name}")
  end

  def safe
    # negative: constant command, no taint
    system("echo hello")
  end
end
