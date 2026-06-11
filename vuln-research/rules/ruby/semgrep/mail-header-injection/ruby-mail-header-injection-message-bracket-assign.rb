# Fixture for the Mail::Message header assignment detector.

def build_message(params)
  message = Mail.new
  # ruleid: ruby-mail-header-injection-message-bracket-assign
  message["X-Priority"] = params[:priority]
  # ruleid: ruby-mail-header-injection-message-bracket-assign
  message["X-Trace"] = "trace-#{params[:trace]}"
  message
end

def build_message_safe
  message = Mail.new
  # ok: ruby-mail-header-injection-message-bracket-assign
  message["X-Priority"] = "normal"
  message
end
