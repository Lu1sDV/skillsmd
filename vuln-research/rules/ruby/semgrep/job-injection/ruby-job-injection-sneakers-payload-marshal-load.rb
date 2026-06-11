# Fixture for unmarshalling a Sneakers AMQP message body.
# Flagged lines reconstruct the body with Marshal; safe line round-trips a trusted object.

class AmqpWorker
  include Sneakers::Worker

  def work(body)
    # ruleid: ruby-job-injection-sneakers-payload-marshal-load
    payload = Marshal.load(body)
    handle(payload)
    ack!
  end

  def work_safe(body)
    # ok: ruby-job-injection-sneakers-payload-marshal-load
    snapshot = Marshal.load(Marshal.dump(@template))
    handle(snapshot)
    ack!
  end
end
