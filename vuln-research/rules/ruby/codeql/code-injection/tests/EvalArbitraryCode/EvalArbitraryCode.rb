class ConsoleController < ActionController::Base
  def run
    snippet = params[:snippet]
    # true positive: tainted parameter passed to instance_eval (arbitrary code)
    Object.new.instance_eval(snippet)
  end

  def safe
    # negative: constant snippet, no taint reaches instance_eval
    Object.new.instance_eval("self.class")
  end
end
