# Fixture for a hardcoded Google API key.
# Flagged assignment embeds an AIza key; the safe line reads it from the environment.

class MapsClient
  def configure
    # ruleid: ruby-hardcoded-secrets-google-api-key
    api_key = "AIzaSyB1c3D5e7F9g0H2i4J6k8L0m1N3o5P7q9r"

    # ok: ruby-hardcoded-secrets-google-api-key
    api_key_safe = ENV["GOOGLE_MAPS_API_KEY"]
    [api_key, api_key_safe]
  end
end
