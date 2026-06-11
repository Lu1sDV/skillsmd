# Fixture for the File.read path-injection rule.
# The flagged calls take an attacker-controlled path; the safe call uses a fixed root.

def show_log
  # ruleid: ruby-path-traversal-file-read
  File.read(params[:filename])
end

def show_report
  # ruleid: ruby-path-traversal-file-read
  File.read("/var/reports/#{params[:name]}")
end

def fixed_banner
  # ok: ruby-path-traversal-file-read
  File.read("/etc/app/banner.txt")
end
