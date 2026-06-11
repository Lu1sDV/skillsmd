# Fixture for ERB compiled from a file whose path comes from request input.

class ImportController
  def run(params)
    # ruleid: ruby-ssti-erb-file-read-interp
    ERB.new(File.read(params[:file])).result(binding)
  end

  def run_safe
    # ok: ruby-ssti-erb-file-read-interp
    ERB.new(File.read("config/report.erb")).result(binding)
  end
end
