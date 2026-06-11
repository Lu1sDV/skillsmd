# Fixture for the Open3.pipeline string-stage detector.

def filtered_logs(term)
  # ruleid: ruby-command-injection-open3-pipeline
  Open3.pipeline("cat /var/log/app.log", "grep #{term}")
end

def filtered_logs_safe(term)
  # ok: ruby-command-injection-open3-pipeline
  Open3.pipeline(["cat", "/var/log/app.log"], ["grep", term])
end
