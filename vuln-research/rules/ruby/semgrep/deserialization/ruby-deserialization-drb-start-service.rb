# Fixture for the DRb.start_service rule.
# Flagged line exports an object over DRb; safe line starts a service with no front object.

require "drb"

def expose(front)
  # ruleid: ruby-deserialization-drb-start-service
  DRb.start_service("druby://0.0.0.0:8787", front)
end

def expose_none
  # ok: ruby-deserialization-drb-start-service
  DRb.start_service
end
