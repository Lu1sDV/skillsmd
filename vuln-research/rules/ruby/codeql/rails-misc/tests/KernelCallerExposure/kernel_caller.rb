class DiagnosticsController < ApplicationController

  # Unsafe: the current call stack is rendered to the client.
  def trace
    frames = caller()
    render body: frames, content_type: "text/plain"
  end

  # Safe: a backtrace from a rescued exception is not Kernel#caller, so this
  # query (which targets caller() specifically) must not flag it.
  def other
    work()
  rescue => e
    render body: e.backtrace, content_type: "text/plain"
  end

end
