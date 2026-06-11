require "securerandom"

# Insecure: predictable index into a charset builds a guessable one-character token.
token = "abcdefghijklmnopqrstuvwxyz0123456789".chars[rand(36)]

# Safe: a cryptographically secure alternative.
safe_token = SecureRandom.alphanumeric(1)
