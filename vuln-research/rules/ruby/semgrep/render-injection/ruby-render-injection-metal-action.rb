# Fixture for dynamic controller action dispatch from request input.

class RackEntry
  def call(env)
    params = ActionDispatch::Request.new(env).params
    # ruleid: ruby-render-injection-metal-action
    ApiController.action(params[:action]).call(env)
  end

  def safe_call(env)
    # ok: ruby-render-injection-metal-action
    ApiController.action(:index).call(env)
  end
end
