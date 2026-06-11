# Fixture for Tilt compiling an interpolated template body.

def render_email(body)
  # ruleid: ruby-ssti-tilt-new-interp
  Tilt::ERBTemplate.new { "Dear customer, #{body}" }.render
end

def render_email_file
  # ok: ruby-ssti-tilt-new-interp
  Tilt::ERBTemplate.new("emails/welcome.erb").render(self, name: "x")
end
