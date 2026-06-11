# Fixture for unsafe YAML loading of a Karafka Kafka message payload.
# Flagged lines load the payload unsafely; safe line decodes JSON.

class EventsConsumer < Karafka::BaseConsumer
  def consume
    messages.each do |message|
      # ruleid: ruby-job-injection-karafka-consumer-yaml-payload
      data = YAML.load(message.raw_payload)
      handle(data)
    end
  end

  def consume_safe
    messages.each do |message|
      # ok: ruby-job-injection-karafka-consumer-yaml-payload
      data = JSON.parse(message.raw_payload)
      handle(data)
    end
  end
end
