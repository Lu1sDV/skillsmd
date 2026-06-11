# Fixture for the mail gem block DSL interpolation detector.

def send_notice(params)
  Mail.deliver do
    # ruleid: ruby-mail-header-injection-deliver-dsl-interp
    to "#{params[:email]}"
    from "noreply@example.com"
    body "Hello"
  end
end

def send_notice_safe(address)
  Mail.deliver do
    # ok: ruby-mail-header-injection-deliver-dsl-interp
    to address
    from "noreply@example.com"
    body "Hello"
  end
end
