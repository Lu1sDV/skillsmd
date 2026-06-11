# Fixture for Dalli/Memcached access under an attacker-influenced key.
# Flagged calls take the key from params; safe call namespaces by account id.

class MemcacheStore
  def initialize(client)
    @dc = client
  end

  def read(params)
    # ruleid: ruby-cache-poisoning-dalli-tainted-key
    @dc.get(params[:key])
  end

  def write(params)
    # ruleid: ruby-cache-poisoning-dalli-tainted-key
    @dc.set("frag:#{params[:slug]}", render_fragment)
  end

  def safe_read(account)
    # ok: ruby-cache-poisoning-dalli-tainted-key
    @dc.get("frag:#{account.id}")
  end
end
