# Fixture for the IO.popen string-command detector.

def read_proc(pattern)
  # ruleid: ruby-command-injection-io-popen
  IO.popen("ps aux | grep #{pattern}", "r") { |io| io.read }
end

def read_proc_safe(pattern)
  # ok: ruby-command-injection-io-popen
  IO.popen(["grep", pattern, "/etc/passwd"]) { |io| io.read }
end
