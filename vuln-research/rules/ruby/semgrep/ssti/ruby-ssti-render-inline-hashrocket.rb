# Fixture for legacy hash-rocket inline rendering of interpolated source.

class ReportController
  def build(params)
    # ruleid: ruby-ssti-render-inline-hashrocket
    render(:inline => "Report for #{params[:client]}")
  end

  def build_safe(params)
    # ok: ruby-ssti-render-inline-hashrocket
    render(:inline => "Report for <%= client %>", :locals => { client: params[:client] })
  end
end
