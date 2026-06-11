# Fixture for a custom ActiveJob serializer using Marshal on stored data.
# The flagged deserialize unmarshals the stored blob; the safe one deep-copies a trusted default.

class MarshalSerializer < ActiveJob::Serializers::ObjectSerializer
  # ruleid: ruby-job-injection-activejob-deserialize-marshal
  def deserialize(hash)
    blob = Base64.decode64(hash["blob"])
    Marshal.load(blob)
  end
end

class CopySerializer < ActiveJob::Serializers::ObjectSerializer
  # ok: ruby-job-injection-activejob-deserialize-marshal
  def deserialize(hash)
    template = DEFAULTS.fetch(hash["kind"])
    Marshal.load(Marshal.dump(template))
  end
end
