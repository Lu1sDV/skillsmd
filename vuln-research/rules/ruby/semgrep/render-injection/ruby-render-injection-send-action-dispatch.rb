# Fixture for action dispatch via send using request input.

class CommandController < ApplicationController
  def run
    # ruleid: ruby-render-injection-send-action-dispatch
    public_send(params[:op])
  end

  def safe_run
    # ok: ruby-render-injection-send-action-dispatch
    public_send(PERMITTED_OPS.fetch(params[:op]))
  end
end
