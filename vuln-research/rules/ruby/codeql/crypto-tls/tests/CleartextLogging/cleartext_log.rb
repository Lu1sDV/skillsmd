require "logger"

class SessionController
  def initialize
    @logger = Logger.new($stdout)
  end

  # True positive: a password is written to the log in clear text.
  def sign_in(password)
    @logger.info("authenticating with password=#{password}")
  end

  # Safe: logging a non-sensitive request id reveals nothing secret.
  def trace(request_id)
    @logger.info("handling request #{request_id}")
  end
end
