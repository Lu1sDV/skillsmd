# ruleid: ruby-hardcoded-secrets-secrets-hash-credential
api_key = "sk_live_4eC39HqLyjWDarjtT1zdp7dc"

# ruleid: ruby-hardcoded-secrets-secrets-hash-credential
db_password = "hunter2-correct-horse"

# ruleid: ruby-hardcoded-secrets-secrets-hash-credential
client_secret = "abc123def456ghi789"

# ok: ruby-hardcoded-secrets-secrets-hash-credential
api_key = ENV["STRIPE_API_KEY"]

# ok: ruby-hardcoded-secrets-secrets-hash-credential
db_password = Rails.application.credentials.db_password

# ok: ruby-hardcoded-secrets-secrets-hash-credential
username = "service-account"
