require "securerandom"

# Insecure: a predictable Kernel#rand value drives selection from a charset,
# producing a guessable token.
token = "abcdefghijklmnopqrstuvwxyz0123456789".chars[rand(36)]

# Safe: a cryptographically secure source is used instead.
safe_token = SecureRandom.alphanumeric(1)
