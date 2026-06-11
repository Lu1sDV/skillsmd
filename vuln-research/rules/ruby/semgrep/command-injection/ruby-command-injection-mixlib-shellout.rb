# Fixture for the Mixlib::ShellOut string-command detector.

def service_status(name)
  # ruleid: ruby-command-injection-mixlib-shellout
  Mixlib::ShellOut.new("systemctl status #{name}").run_command
end

def service_status_safe(name)
  # ok: ruby-command-injection-mixlib-shellout
  Mixlib::ShellOut.new("systemctl", "status", name).run_command
end
