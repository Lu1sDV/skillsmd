# Fixture mimicking a compiled ERB view that caches a fragment.
# Flagged blocks key the fragment on params; safe block keys on the record.

def render_sidebar
  # ruleid: ruby-cache-poisoning-fragment-cache-tainted-key
  cache(params[:section]) { expensive_sidebar }

  # ruleid: ruby-cache-poisoning-fragment-cache-tainted-key
  cache("sidebar/#{params[:org]}") { expensive_sidebar }

  # ok: ruby-cache-poisoning-fragment-cache-tainted-key
  cache(@article) { expensive_sidebar }
end
