# Fixture for coupon-code generation via rand.

def new_coupon
  # ruleid: ruby-insecure-randomness-rand-uniq-coupon
  coupon = rand(36**8).to_s(36).upcase
  coupon
end

def new_coupon_secure
  # ok: ruby-insecure-randomness-rand-uniq-coupon
  coupon = SecureRandom.alphanumeric(8).upcase
  coupon
end
