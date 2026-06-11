# Fixture for the File.readlines / File.foreach path-injection rule.

def dump_lines
  # ruleid: ruby-path-traversal-file-readlines
  File.readlines(params[:log])
end

def each_named
  # ruleid: ruby-path-traversal-file-readlines
  File.foreach("/var/log/#{params[:app]}") { |l| puts l }
end

def each_fixed
  # ok: ruby-path-traversal-file-readlines
  File.foreach("/var/log/app.log") { |l| puts l }
end
