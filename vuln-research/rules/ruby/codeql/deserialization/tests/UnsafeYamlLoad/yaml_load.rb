class ImportsController < ApplicationController
  def load_config
    data = params[:config]
    # Attacker-controlled data reaches YAML.unsafe_load -> arbitrary object creation.
    cfg = YAML.unsafe_load(data)
    render plain: cfg.inspect
  end

  def safe_load_config
    data = params[:config]
    # safe_load restricts permitted classes; not a sink.
    cfg = YAML.safe_load(data)
    render plain: cfg.inspect
  end
end
