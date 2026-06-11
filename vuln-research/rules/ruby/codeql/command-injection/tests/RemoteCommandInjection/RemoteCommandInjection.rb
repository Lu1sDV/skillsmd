class PingController < ActionController::Base
  def ping
    host = params[:host]
    # true positive: HTTP parameter reaches a backtick command
    output = `ping -c1 #{host}`
    render plain: output
  end

  def safe_ping
    # negative: hardcoded host, nothing remote flows in
    render plain: `ping -c1 127.0.0.1`
  end
end
