# Fixture for the GlobalID::Locator.locate rule.
# Flagged line locates from a request GID; safe lines pin a literal or constrain the type.

def fetch(params)
  # ruleid: ruby-deserialization-globalid-locate
  GlobalID::Locator.locate(params[:gid])
end

def fetch_scoped(params)
  # ok: ruby-deserialization-globalid-locate
  GlobalID::Locator.locate(params[:gid], only: Document)
end

def fetch_const
  # ok: ruby-deserialization-globalid-locate
  GlobalID::Locator.locate("gid://app/Document/1")
end
