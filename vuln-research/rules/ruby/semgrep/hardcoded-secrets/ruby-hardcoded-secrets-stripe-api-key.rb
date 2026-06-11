# Fixture for hardcoded Stripe secret API key.
# Flagged assignment inlines a live key; the safe line reads it from the environment.

class PaymentGateway
  def configure
    # ruleid: ruby-hardcoded-secrets-stripe-api-key
    Stripe.api_key = "sk_live_51HabcdEFGHijklMNOPqrstUVWX"

    # ok: ruby-hardcoded-secrets-stripe-api-key
    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
  end
end
