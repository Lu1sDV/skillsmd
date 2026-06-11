# Fixture for a MongoDB URI with inline credentials.
# Flagged assignment embeds user:password; the safe line reads the URI from the environment.

class MongoConfig
  def uri
    # ruleid: ruby-hardcoded-secrets-mongoid-uri-credentials
    Mongo::Client.new("mongodb+srv://appuser:Sup3rMongoPass@cluster0.mongodb.net/app")

    # ok: ruby-hardcoded-secrets-mongoid-uri-credentials
    Mongo::Client.new(ENV["MONGODB_URI"])
  end
end
