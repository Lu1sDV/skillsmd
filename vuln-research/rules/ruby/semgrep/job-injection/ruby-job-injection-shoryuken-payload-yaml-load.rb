# Fixture for unsafe YAML loading of a Shoryuken SQS message body.
# Flagged lines load the body with an unsafe parser; safe line uses safe_load.

class InboundWorker
  include Shoryuken::Worker

  def perform(sqs_msg, body)
    # ruleid: ruby-job-injection-shoryuken-payload-yaml-load
    payload = YAML.load(sqs_msg.body)

    # ruleid: ruby-job-injection-shoryuken-payload-yaml-load
    other = Psych.load(sqs_msg.body)

    process(payload, other)
  end

  def perform_safe(sqs_msg, body)
    # ok: ruby-job-injection-shoryuken-payload-yaml-load
    payload = YAML.safe_load(sqs_msg.body, permitted_classes: [Symbol])
    process(payload)
  end
end
