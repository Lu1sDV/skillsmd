# Fixture for a custom ActiveJob serializer using an unsafe YAML loader.
# The flagged deserialize reconstructs with YAML.load; the safe one uses safe_load.

class UnsafeSerializer < ActiveJob::Serializers::ObjectSerializer
  # ruleid: ruby-job-injection-activejob-deserialize-yaml
  def deserialize(hash)
    blob = hash["yaml"]
    YAML.load(blob)
  end
end

class SafeSerializer < ActiveJob::Serializers::ObjectSerializer
  # ok: ruby-job-injection-activejob-deserialize-yaml
  def deserialize(hash)
    blob = hash["yaml"]
    YAML.safe_load(blob, permitted_classes: [Time])
  end
end
