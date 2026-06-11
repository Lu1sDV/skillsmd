# Test fixture for ruby-system-interp.
# Lines flagged below must match; lines marked safe must not.

def backup(name)
  # ruleid: ruby-system-interp
  system("tar czf /tmp/#{name}.tgz /data")
end

def ping(host)
  # ruleid: ruby-system-interp
  system("ping -c1 #{host}", err: :out)
end

def safe_backup(name)
  # ok: ruby-system-interp
  system("tar", "czf", "/tmp/#{name}.tgz", "/data")
end

def static_call
  # ok: ruby-system-interp
  system("ls -la /tmp")
end
