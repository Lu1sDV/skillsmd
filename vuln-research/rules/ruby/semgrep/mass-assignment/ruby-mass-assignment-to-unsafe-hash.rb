# Fixture for the to-unsafe-hash rule.

def raw_hash
  # ruleid: ruby-mass-assignment-to-unsafe-hash
  data = params.to_unsafe_hash
  Account.create(data)
end

def safe_hash
  # ok: ruby-mass-assignment-to-unsafe-hash
  data = params.require(:account).permit(:plan).to_h
  Account.create(data)
end
