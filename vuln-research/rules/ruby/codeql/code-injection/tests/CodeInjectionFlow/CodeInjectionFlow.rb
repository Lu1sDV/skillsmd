class CodeRunnerController < ActionController::Base
  def run
    expr = params[:expr]
    # true positive: tainted parameter evaluated as Ruby source code
    eval(expr)
  end

  def safe
    # negative: constant expression, no taint reaches eval
    eval("1 + 1")
  end
end
