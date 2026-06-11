# Fixture for the Open3.capture2e string-command detector.

def probe(host)
  # ruleid: ruby-command-injection-open3-capture2e
  Open3.capture2e("nmap #{host}")
end

def probe_safe(host)
  # ok: ruby-command-injection-open3-capture2e
  Open3.capture2e("nmap", host)
end
