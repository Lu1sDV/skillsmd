# Fixture for raw Redis command dispatch built from request data.
# Flagged calls take the command from params; safe call uses a fixed command.

class RedisAdmin
  def initialize(redis)
    @redis = redis
  end

  def run(params)
    # ruleid: ruby-cache-poisoning-redis-call-tainted-command
    @redis.call(params[:cmd], params[:arg])

    # ruleid: ruby-cache-poisoning-redis-call-tainted-command
    @redis.call([params[:cmd], "k"])
  end

  def safe_run(user)
    # ok: ruby-cache-poisoning-redis-call-tainted-command
    @redis.call("GET", "tok:#{user.id}")
  end
end
