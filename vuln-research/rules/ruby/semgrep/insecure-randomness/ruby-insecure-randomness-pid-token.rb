# Fixture for PID-derived sensitive values.

def worker_token
  # ruleid: ruby-insecure-randomness-pid-token
  job_token = "job-#{Process.pid}-x"
  job_token
end

def worker_token_secure
  # ok: ruby-insecure-randomness-pid-token
  job_token = SecureRandom.hex(8)
  job_token
end

def current_worker
  # ok: ruby-insecure-randomness-pid-token
  worker_label = Process.pid
  worker_label
end
