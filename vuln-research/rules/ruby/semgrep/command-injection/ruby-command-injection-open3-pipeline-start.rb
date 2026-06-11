# Fixture for the Open3.pipeline_start string-stage detector.

def stream(term)
  # ruleid: ruby-command-injection-open3-pipeline-start
  Open3.pipeline_start("tail -f app.log", "grep #{term}")
end

def stream_safe(term)
  # ok: ruby-command-injection-open3-pipeline-start
  Open3.pipeline_start(["tail", "-f", "app.log"], ["grep", term])
end
