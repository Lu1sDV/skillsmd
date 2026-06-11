# Fixture for the controller render class method with request-controlled template.

class NotifyJob
  def perform(template_param)
    # ruleid: ruby-render-injection-base-render-class-method
    body = ApplicationController.render(template: params[:tpl])
    deliver(body)
  end

  def safe_perform
    # ok: ruby-render-injection-base-render-class-method
    body = ApplicationController.render(template: "notifications/welcome")
    deliver(body)
  end
end
