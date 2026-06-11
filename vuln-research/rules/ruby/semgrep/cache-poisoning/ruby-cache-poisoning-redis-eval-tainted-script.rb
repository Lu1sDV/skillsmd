# Fixture for Redis Lua evaluation with a dynamic script body.
# Flagged calls interpolate request data into the script; safe call uses a fixed script with ARGV.

class CounterScript
  FIXED = "return redis.call('incr', KEYS[1])"

  def initialize(redis)
    @redis = redis
  end

  def run(params)
    # ruleid: ruby-cache-poisoning-redis-eval-tainted-script
    @redis.eval(params[:lua])

    # ruleid: ruby-cache-poisoning-redis-eval-tainted-script
    @redis.eval("return redis.call('get', '#{params[:key]}')")
  end

  def safe_run(user)
    # ok: ruby-cache-poisoning-redis-eval-tainted-script
    @redis.eval(FIXED, keys: ["counter:#{user.id}"])
  end
end
